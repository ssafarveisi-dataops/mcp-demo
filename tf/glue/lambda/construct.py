from typing import Any, Dict


class InvalidInputError(Exception):
    """Raised when the incoming Step Functions payload is invalid."""


def to_pascal_case(value: str) -> str:
    """
    Convert snake_case to PascalCase.

    Examples:
        events -> Events
        double_classifier -> DoubleClassifier
    """
    return "".join(part.capitalize() for part in value.split("_"))


def build_training_input(event: Dict[str, Any]) -> Dict[str, str]:
    """
    Expected key format:
        raw/project/year/month/day/file.csv

    Example:
        raw/double_classifier/2026/05/11/file.csv
    """
    try:
        bucket = event["bucket"]["name"]
        key = event["object"]["key"]
    except KeyError as e:
        raise InvalidInputError(f"Missing required field: {e}")

    parts = key.split("/")

    # Expected:
    # raw/<project>/<year>/<month>/<day>/<file>
    if len(parts) != 6:
        raise InvalidInputError(
            f"Unexpected key format: {key}. "
            "Expected: raw/project/year/month/day/file.csv"
        )

    if parts[0] != "raw":
        raise InvalidInputError(
            f"Unexpected prefix: {parts[0]}. Expected 'raw'."
        )

    project = parts[1]
    project_pascal = to_pascal_case(project)

    prefix = "/".join(
        [
            "transformed",
            parts[1],  # project
            parts[2],  # year
            parts[3],  # month
            parts[4],  # day
        ]
    )

    return {
        "bucket": bucket,
        "prefix": prefix,
        "project": project,
        "project_pascal": project_pascal,
        "state_machine_name": f"Metaflow{project_pascal}",
    }


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda entrypoint for AWS Step Functions.
    """
    return build_training_input(event)
