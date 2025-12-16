"""Tests for logger."""

import pytest
from io import StringIO
import sys

from wasm.core.logger import Logger


class TestLogger:
    """Tests for Logger class."""
    
    def test_logger_creation(self):
        """Test logger can be created."""
        logger = Logger()
        assert logger is not None
    
    def test_verbose_mode(self):
        """Test verbose mode configuration."""
        logger = Logger(verbose=True)
        assert logger.verbose is True
        
        logger = Logger(verbose=False)
        assert logger.verbose is False
    
    def test_info_output(self, capsys):
        """Test info message output."""
        logger = Logger(verbose=False)
        logger.info("Test message")
        captured = capsys.readouterr()
        assert "Test message" in captured.out
    
    def test_debug_hidden_without_verbose(self, capsys):
        """Test debug messages are hidden without verbose."""
        logger = Logger(verbose=False)
        logger.debug("Debug message")
        captured = capsys.readouterr()
        assert "Debug message" not in captured.out
    
    def test_debug_shown_with_verbose(self, capsys):
        """Test debug messages are shown with verbose."""
        logger = Logger(verbose=True)
        logger.debug("Debug message")
        captured = capsys.readouterr()
        assert "Debug message" in captured.out
    
    def test_error_output(self, capsys):
        """Test error message output."""
        logger = Logger(verbose=False)
        logger.error("Error message")
        captured = capsys.readouterr()
        assert "Error message" in captured.out
    
    def test_step_format(self, capsys):
        """Test step message format."""
        logger = Logger(verbose=False)
        logger.step(1, 5, "First step")
        captured = capsys.readouterr()
        assert "[1/5]" in captured.out
        assert "First step" in captured.out
