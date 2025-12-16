"""Tests for domain validator."""

import pytest

from wasm.validators.domain import (
    is_valid_domain,
    validate_domain,
    extract_domain_parts,
    is_subdomain,
)
from wasm.core.exceptions import ValidationError


class TestIsValidDomain:
    """Tests for is_valid_domain function."""
    
    def test_valid_domains(self):
        """Test valid domain names."""
        valid_domains = [
            "example.com",
            "www.example.com",
            "sub.domain.example.com",
            "example-site.com",
            "123.example.com",
            "ex.co",
            "example.co.uk",
        ]
        for domain in valid_domains:
            assert is_valid_domain(domain) is True, f"Expected {domain} to be valid"
    
    def test_invalid_domains(self):
        """Test invalid domain names."""
        invalid_domains = [
            "",
            "example",
            ".example.com",
            "example.com.",
            "example..com",
            "-example.com",
            "example-.com",
            "example.c",
            "example." + "a" * 64 + ".com",  # label too long
            "http://example.com",
            "example.com/path",
            "example.com:8080",
            "example_site.com",
            "exam ple.com",
        ]
        for domain in invalid_domains:
            assert is_valid_domain(domain) is False, f"Expected {domain} to be invalid"


class TestValidateDomain:
    """Tests for validate_domain function."""
    
    def test_valid_domain_returns_normalized(self):
        """Test that validate_domain returns normalized domain."""
        assert validate_domain("EXAMPLE.COM") == "example.com"
        assert validate_domain("  example.com  ") == "example.com"
    
    def test_invalid_domain_raises_error(self):
        """Test that validate_domain raises ValidationError for invalid domains."""
        with pytest.raises(ValidationError):
            validate_domain("invalid")
        
        with pytest.raises(ValidationError):
            validate_domain("")


class TestExtractDomainParts:
    """Tests for extract_domain_parts function."""
    
    def test_simple_domain(self):
        """Test extracting parts from simple domain."""
        parts = extract_domain_parts("example.com")
        assert parts["subdomain"] is None
        assert parts["domain"] == "example"
        assert parts["tld"] == "com"
    
    def test_domain_with_subdomain(self):
        """Test extracting parts from domain with subdomain."""
        parts = extract_domain_parts("www.example.com")
        assert parts["subdomain"] == "www"
        assert parts["domain"] == "example"
        assert parts["tld"] == "com"
    
    def test_domain_with_multiple_subdomains(self):
        """Test extracting parts from domain with multiple subdomains."""
        parts = extract_domain_parts("a.b.c.example.com")
        assert parts["subdomain"] == "a.b.c"
        assert parts["domain"] == "example"
        assert parts["tld"] == "com"


class TestIsSubdomain:
    """Tests for is_subdomain function."""
    
    def test_is_subdomain(self):
        """Test subdomain detection."""
        assert is_subdomain("www.example.com") is True
        assert is_subdomain("api.example.com") is True
        assert is_subdomain("a.b.example.com") is True
    
    def test_is_not_subdomain(self):
        """Test non-subdomain detection."""
        assert is_subdomain("example.com") is False
        assert is_subdomain("example.co.uk") is False
