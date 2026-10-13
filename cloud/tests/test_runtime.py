"""Exercise recovery and local-work preservation using real Git repositories."""

import importlib.util
import io
import os
import subprocess
import tarfile
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


repositories = load("cloud_repositories", ROOT / "repositories.py")
skills = load("cloud_skills_state", ROOT / "skills-state.py")
typst = load("cloud_typst_cache", ROOT / "typst-cache.py")


def git(path, *args):
    return subprocess.check_output(
        ["git", "-C", str(path), *args],
        text=True,
        stderr=subprocess.DEVNULL,
        env=repositories.git_environment(),
    ).strip()


class RepositoryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.remote = self.root / "origin.git"
        subprocess.run(
            ["git", "init", "--bare", "--initial-branch=main", str(self.remote)],
            check=True,
            capture_output=True,
            env=repositories.git_environment(),
        )
        self.writer = self.root / "writer"
        subprocess.run(
            ["git", "clone", str(self.remote), str(self.writer)],
            check=True,
            capture_output=True,
            env=repositories.git_environment(),
        )
        git(self.writer, "config", "user.name", "Fixture")
        git(self.writer, "config", "user.email", "fixture@example.test")
        self.publish("first")
        self.workspace = self.root / "workspace"
        self.repository, state = repositories.sync_repository(
            self.workspace, "team/project", str(self.remote)
        )
        self.assertEqual(state, "ready")
        git(self.repository, "config", "user.name", "Fixture")
        git(self.repository, "config", "user.email", "fixture@example.test")

    def publish(self, content):
        (self.writer / "tracked.txt").write_text(content)
        git(self.writer, "add", "tracked.txt")
        git(self.writer, "commit", "-m", content)
        git(self.writer, "push", "origin", "main")

    def test_clean_default_branch_fast_forwards(self):
        self.publish("second")
        _, state = repositories.sync_repository(self.workspace, "team/project")
        self.assertEqual(state, "ready")
        self.assertEqual((self.repository / "tracked.txt").read_text(), "second")

    def test_uncommitted_changes_are_preserved(self):
        (self.repository / "tracked.txt").write_text("user work")
        self.publish("second")
        before = git(self.repository, "rev-parse", "HEAD")
        _, state = repositories.sync_repository(self.workspace, "team/project")
        self.assertEqual(state, "local-changes")
        self.assertEqual(git(self.repository, "rev-parse", "HEAD"), before)
        self.assertEqual((self.repository / "tracked.txt").read_text(), "user work")

    def test_task_branch_is_preserved(self):
        git(self.repository, "checkout", "-b", "task")
        self.publish("second")
        _, state = repositories.sync_repository(self.workspace, "team/project")
        self.assertEqual(state, "task-branch")
        self.assertEqual(git(self.repository, "branch", "--show-current"), "task")

    def test_unpushed_commits_are_preserved(self):
        (self.repository / "tracked.txt").write_text("local commit")
        git(self.repository, "add", "tracked.txt")
        git(self.repository, "commit", "-m", "local")
        self.publish("second")
        before = git(self.repository, "rev-parse", "HEAD")
        _, state = repositories.sync_repository(self.workspace, "team/project")
        self.assertEqual(state, "local-commits")
        self.assertEqual(git(self.repository, "rev-parse", "HEAD"), before)

    def test_non_repository_and_path_escape_are_rejected(self):
        directory = self.workspace / "team/notes"
        directory.mkdir()
        (directory / "user.txt").write_text("keep")
        with self.assertRaises(RuntimeError):
            repositories.sync_repository(self.workspace, "team/notes")
        self.assertEqual((directory / "user.txt").read_text(), "keep")
        with self.assertRaises(ValueError):
            repositories.sync_repository(self.workspace, "../escape")

    def test_git_hook_context_cannot_redirect_repository_operations(self):
        self.publish("second")
        outer_index = self.writer / ".git/index"
        previous = outer_index.read_bytes()
        with patch.dict(
            os.environ,
            {
                "GIT_DIR": str(self.writer / ".git"),
                "GIT_WORK_TREE": str(self.writer),
                "GIT_INDEX_FILE": str(outer_index),
            },
        ):
            _, state = repositories.sync_repository(self.workspace, "team/project")
        self.assertEqual(state, "ready")
        self.assertEqual((self.repository / "tracked.txt").read_text(), "second")
        self.assertEqual(outer_index.read_bytes(), previous)


class RecoveryTests(unittest.TestCase):
    def test_failed_skill_update_restores_files_lock_and_symlinks(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            agent = root / "agent"
            collection = agent / "skills"
            collection.mkdir(parents=True)
            (collection / "SKILL.md").write_text("previous working instructions")
            (agent / ".skill-lock.json").write_text('{"source": "previous"}')
            (agent / "notes.txt").write_text("unrelated user data")
            (root / "linked.txt").write_text("user linked skill")
            (collection / "linked").symlink_to(root / "linked.txt")
            run = root / "run"
            skills.snapshot(agent, run)
            (collection / "SKILL.md").write_text("partial failed update")
            (collection / "new-skill.txt").write_text("partial")
            (agent / ".skill-lock.json").write_text('{"source": "partial"}')
            skills.restore(agent, run)
            self.assertEqual(
                (collection / "SKILL.md").read_text(), "previous working instructions"
            )
            self.assertEqual(
                (agent / ".skill-lock.json").read_text(), '{"source": "previous"}'
            )
            self.assertTrue((collection / "linked").is_symlink())
            self.assertEqual((collection / "linked").read_text(), "user linked skill")
            self.assertFalse((collection / "new-skill.txt").exists())
            self.assertEqual((agent / "notes.txt").read_text(), "unrelated user data")
            self.assertEqual(
                (run / "failed-collection/skills/new-skill.txt").read_text(), "partial"
            )

    def test_failed_first_install_keeps_no_partial_ready_collection(self):
        with tempfile.TemporaryDirectory() as temporary:
            agent, run = Path(temporary) / "agent", Path(temporary) / "run"
            skills.snapshot(agent, run)
            (agent / "skills").mkdir(parents=True)
            (agent / "skills/SKILL.md").write_text("partial")
            skills.restore(agent, run)
            self.assertFalse((agent / "skills").exists())
            self.assertTrue((run / "failed-collection/skills/SKILL.md").exists())


def package(name, version, content):
    data = io.BytesIO()
    with tarfile.open(fileobj=data, mode="w:gz") as archive:
        for filename, text in {
            "typst.toml": f'[package]\nname = "{name}"\nversion = "{version}"\n',
            "lib.typ": content,
        }.items():
            encoded = text.encode()
            info = tarfile.TarInfo(filename)
            info.size = len(encoded)
            archive.addfile(info, io.BytesIO(encoded))
    return data.getvalue()


class TypstTests(unittest.TestCase):
    def test_prefetches_transitive_pinned_imports_and_reuses_cache(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "source"
            source.mkdir()
            (source / "resume.typ").write_text('#import "@preview/first:0.1.0": *')
            cache = Path(temporary) / "cache"
            archives = {
                "https://packages.typst.org/preview/first-0.1.0.tar.gz": package(
                    "first", "0.1.0", '#import "@preview/second:0.2.0": *'
                ),
                "https://packages.typst.org/preview/second-0.2.0.tar.gz": package(
                    "second", "0.2.0", "#let value = 1"
                ),
            }
            with patch.object(
                typst.urllib.request,
                "urlopen",
                side_effect=lambda url, timeout: io.BytesIO(archives[url]),
            ) as request:
                typst.main([source], cache)
                self.assertEqual(request.call_count, 2)
                typst.main([source], cache)
                self.assertEqual(request.call_count, 2)
            self.assertTrue((cache / "second/0.2.0/typst.toml").exists())


if __name__ == "__main__":
    unittest.main()
