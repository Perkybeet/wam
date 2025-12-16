"""Tests for source validator."""

import pytest

from wasm.validators.source import (
    is_valid_source,
    validate_source,
    parse_source,
    is_git_url,
    is_github_shorthand,
)
from wasm.core.exceptions import ValidationError


class TestIsGitUrl:
    """Tests for is_git_url function."""
    
    def test_ssh_git_urls(self):
        """Test SSH Git URLs."""
        assert is_git_url("git@github.com:user/repo.git") is True
        assert is_git_url("git@gitlab.com:user/repo.git") is True
        assert is_git_url("git@bitbucket.org:user/repo.git") is True
    
    def test_https_git_urls(self):
        """Test HTTPS Git URLs."""
        assert is_git_url("https://github.com/user/repo.git") is True
        assert is_git_url("https://github.com/user/repo") is True
        assert is_git_url("https://gitlab.com/user/repo.git") is True
    
    def test_invalid_git_urls(self):
        """Test invalid Git URLs."""
        assert is_git_url("not-a-url") is False
        assert is_git_url("http://example.com") is False
        assert is_git_url("ftp://example.com/repo") is False


class TestIsGitHubShorthand:
    """Tests for is_github_shorthand function."""
    
    def test_valid_shorthand(self):
        """Test valid GitHub shorthand."""
        assert is_github_shorthand("user/repo") is True
        assert is_github_shorthand("my-org/my-repo") is True
        assert is_github_shorthand("user123/repo-name") is True
    
    def test_invalid_shorthand(self):
        """Test invalid GitHub shorthand."""
        assert is_github_shorthand("user") is False
        assert is_github_shorthand("user/repo/extra") is False
        assert is_github_shorthand("") is False


class TestParseSource:
    """Tests for parse_source function."""
    
    def test_git_ssh_url(self):
        """Test parsing SSH Git URL."""
        result = parse_source("git@github.com:user/repo.git")
        assert result["type"] == "git"
        assert result["url"] == "git@github.com:user/repo.git"
    
    def test_git_https_url(self):
        """Test parsing HTTPS Git URL."""
        result = parse_source("https://github.com/user/repo.git")
        assert result["type"] == "git"
        assert result["url"] == "https://github.com/user/repo.git"
    
    def test_github_shorthand(self):
        """Test parsing GitHub shorthand."""
        result = parse_source("user/repo")
        assert result["type"] == "git"
        assert "github.com" in result["url"]
    
    def test_local_path(self):
        """Test parsing local path."""
        result = parse_source("/path/to/local")
        assert result["type"] == "local"
        assert result["path"] == "/path/to/local"


class TestValidateSource:
    """Tests for validate_source function."""
    
    def test_valid_sources(self):
        """Test validation of valid sources."""
        # Git URLs
        info = validate_source("git@github.com:user/repo.git")
        assert info["type"] == "git"
        
        # GitHub shorthand
        info = validate_source("user/repo")
        assert info["type"] == "git"
    
    def test_invalid_source_raises_error(self):
        """Test that invalid sources raise ValidationError."""
        with pytest.raises(ValidationError):
            validate_source("")
