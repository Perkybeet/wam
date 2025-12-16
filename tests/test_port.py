"""Tests for port validator."""

import pytest

from wasm.validators.port import (
    is_valid_port,
    validate_port,
    is_port_available,
    get_default_port,
)
from wasm.core.exceptions import ValidationError


class TestIsValidPort:
    """Tests for is_valid_port function."""
    
    def test_valid_ports(self):
        """Test valid port numbers."""
        valid_ports = [1, 80, 443, 3000, 8080, 65535]
        for port in valid_ports:
            assert is_valid_port(port) is True, f"Expected {port} to be valid"
    
    def test_invalid_ports(self):
        """Test invalid port numbers."""
        invalid_ports = [0, -1, 65536, 100000]
        for port in invalid_ports:
            assert is_valid_port(port) is False, f"Expected {port} to be invalid"
    
    def test_string_ports(self):
        """Test port validation with string input."""
        assert is_valid_port("3000") is True
        assert is_valid_port("invalid") is False
        assert is_valid_port("") is False


class TestValidatePort:
    """Tests for validate_port function."""
    
    def test_valid_port_returns_int(self):
        """Test that validate_port returns integer."""
        assert validate_port(3000) == 3000
        assert validate_port("3000") == 3000
    
    def test_invalid_port_raises_error(self):
        """Test that validate_port raises ValidationError for invalid ports."""
        with pytest.raises(ValidationError):
            validate_port(0)
        
        with pytest.raises(ValidationError):
            validate_port(70000)


class TestGetDefaultPort:
    """Tests for get_default_port function."""
    
    def test_app_type_ports(self):
        """Test default ports for app types."""
        assert get_default_port("nextjs") == 3000
        assert get_default_port("nodejs") == 3000
        assert get_default_port("vite") == 5173
        assert get_default_port("python") == 8000
        assert get_default_port("static") == 80
    
    def test_unknown_app_type(self):
        """Test default port for unknown app type."""
        assert get_default_port("unknown") == 3000
