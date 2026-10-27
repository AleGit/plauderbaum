"""The model call: one prompt in, one JSON object out.

Each provider module offers `complete(settings, system, user, schema) -> str`,
the model's raw answer. `ask` picks the provider chosen in Settings and checks
the answer.

Cursor is optional: its package is not in the default install. Start with
`--with-cursor` to add it; until then the Cursor provider is unavailable.
"""

from ..errors import TutorError
from ..settings import Settings
from . import claude, openrouter
from .answer import parse_answer

CURSOR_INSTALL_HINT = (
    "Cursor support is not installed. Start with ./run.sh --with-cursor "
    "(or run.bat --with-cursor), then pick Cursor in Settings."
)

PROVIDERS = {
    "anthropic": claude.complete,
    "openrouter": openrouter.complete,
}


def cursor_available() -> bool:
    """Whether the optional cursor-sdk package is importable."""
    try:
        import cursor_sdk  # noqa: F401
    except ImportError:
        return False
    return True


def _providers() -> dict:
    providers = dict(PROVIDERS)
    if cursor_available():
        from . import cursor_agent
        providers["cursor"] = cursor_agent.complete
    return providers


def ask(settings: Settings, system: str, user: str, schema: dict) -> dict:
    """Send one prompt and return the answer as a dict that matches `schema`.

    Raises TutorError with a message for the learner if that does not work out.
    """
    providers = _providers()
    if settings.provider not in providers:
        if settings.provider == "cursor":
            raise TutorError(CURSOR_INSTALL_HINT)
        raise TutorError(f"Unknown provider: {settings.provider}")
    return parse_answer(providers[settings.provider](settings, system, user, schema), schema)
