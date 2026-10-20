"""Print measured vulnerability counts from the three saved Trivy reports."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

for name in ("insecure", "secure", "distroless"):
    path = ROOT / "reports" / f"{name}.json"
    print(f"\n=== {name} ===")
    if not path.exists():
        print(f"Report missing: {path.name}")
        continue

    data = json.loads(path.read_text(encoding="utf-8"))
    findings = [
        (result, vulnerability)
        for result in (data.get("Results") or [])
        for vulnerability in (result.get("Vulnerabilities") or [])
        if vulnerability.get("Severity") in {"CRITICAL", "HIGH"}
    ]

    for severity in ("CRITICAL", "HIGH"):
        selected = [
            (result, vulnerability)
            for result, vulnerability in findings
            if vulnerability.get("Severity") == severity
        ]
        fixed = sum(bool(v.get("FixedVersion")) for _, v in selected)
        os_count = sum(r.get("Class") == "os-pkgs" for r, _ in selected)
        python_count = sum(r.get("Type") == "python-pkg" for r, _ in selected)
        print(
            f"{severity}: total={len(selected)}, fixable={fixed}, "
            f"os={os_count}, python={python_count}"
        )

    if name == "insecure":
        print("CVE examples to investigate:")
        ordered = sorted(
            findings,
            key=lambda item: (
                item[1].get("Severity") != "CRITICAL",
                item[1].get("VulnerabilityID", ""),
            ),
        )
        seen = set()
        for _, vulnerability in ordered:
            cve = vulnerability.get("VulnerabilityID", "")
            if cve in seen:
                continue
            seen.add(cve)
            print(f"  {cve} | {vulnerability.get('PkgName')} | "
                  f"{vulnerability.get('Severity')}")
            print(f"  {vulnerability.get('Title', '')}")
            print(f"  {vulnerability.get('PrimaryURL', '')}")
            if len(seen) == 3:
                break

