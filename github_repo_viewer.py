import os
import git
import tkinter as tk
from tkinter import ttk, messagebox
from tkinter.scrolledtext import ScrolledText

# Define the local repositories directory
LOCAL_REPOS_DIR = "/Users/liborballaty/Documents/Projects/GitHubProjectsDocuments"

class GitHubRepoViewer:
    def __init__(self, root):
        self.root = root
        self.root.title("GitHub Repository Viewer")
        self.root.geometry("800x600")

        # Title Label
        ttk.Label(root, text="GitHub Repositories", font=("Arial", 14, "bold")).pack(pady=10)

        # Repository List
        self.repo_listbox = tk.Listbox(root, height=15)
        self.repo_listbox.pack(fill=tk.BOTH, expand=True, padx=20, pady=5)
        self.repo_listbox.bind("<Double-Button-1>", self.show_repo_contents)

        # Sync Status Text
        self.sync_status = ScrolledText(root, height=5)
        self.sync_status.pack(fill=tk.BOTH, expand=True, padx=20, pady=5)

        # Load repositories
        self.load_repositories()

    def load_repositories(self):
        """Load repositories from the local directory and display them in the listbox."""
        self.repo_listbox.delete(0, tk.END)

        if not os.path.exists(LOCAL_REPOS_DIR):
            messagebox.showerror("Error", f"Directory not found: {LOCAL_REPOS_DIR}")
            return

        repos = [d for d in os.listdir(LOCAL_REPOS_DIR) if os.path.isdir(os.path.join(LOCAL_REPOS_DIR, d))]
        for repo in repos:
            repo_path = os.path.join(LOCAL_REPOS_DIR, repo)
            try:
                git_repo = git.Repo(repo_path)
                status = self.get_sync_status(git_repo)
                self.repo_listbox.insert(tk.END, f"{repo} - {status}")
            except git.exc.InvalidGitRepositoryError:
                self.repo_listbox.insert(tk.END, f"{repo} (Not a Git Repo)")

    def get_sync_status(self, repo):
        """Check if the repository is up-to-date, behind, or has uncommitted changes."""
        repo.git.fetch()
        status = repo.git.status("--short")

        if status:
            return "⚠️ Has Local Changes"
        elif repo.git.status("--branch").find("behind") != -1:
            return "⬇️ Needs Pull"
        elif repo.git.status("--branch").find("ahead") != -1:
            return "⬆️ Has Unpushed Commits"
        else:
            return "✅ Up to Date"

    def show_repo_contents(self, event):
        """Display the directory structure of the selected repository."""
        selection = self.repo_listbox.curselection()
        if not selection:
            return

        selected_repo = self.repo_listbox.get(selection[0]).split(" - ")[0]
        repo_path = os.path.join(LOCAL_REPOS_DIR, selected_repo)

        if not os.path.exists(repo_path):
            messagebox.showerror("Error", f"Repository not found: {repo_path}")
            return

        file_structure = self.get_directory_structure(repo_path)

        # Show repo contents in a pop-up window
        self.show_popup(f"Contents of {selected_repo}", file_structure)

    def get_directory_structure(self, repo_path):
        """Recursively list all files in the repository as a tree."""
        output = []
        for root, dirs, files in os.walk(repo_path):
            indent_level = root.replace(repo_path, "").count(os.sep)
            indent = "  " * indent_level
            output.append(f"{indent}📂 {os.path.basename(root)}")
            for f in files:
                output.append(f"{indent}  📄 {f}")
        return "\n".join(output)

    def show_popup(self, title, content):
        """Create a pop-up window to display the repository file structure."""
        popup = tk.Toplevel(self.root)
        popup.title(title)
        popup.geometry("600x400")

        text_area = ScrolledText(popup, wrap=tk.WORD)
        text_area.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        text_area.insert(tk.END, content)
        text_area.config(state=tk.DISABLED)

# Run the application
if __name__ == "__main__":
    root = tk.Tk()
    app = GitHubRepoViewer(root)
    root.mainloop()

