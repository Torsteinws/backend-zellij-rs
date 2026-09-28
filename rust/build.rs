// rust/build.rs
use std::fs;
use std::path::Path;

fn main() {
    // VERSION lives at the monorepo root, one level up from this crate.
    let version_path = Path::new("..").join("VERSION");

    let version = fs::read_to_string(&version_path)
        .unwrap_or_else(|e| {
            panic!(
                "Failed to read VERSION file at {}: {e}",
                version_path.display()
            )
        })
        .trim()
        .to_string();

    // Expose it to the crate as an env var usable via env!("VERSION").
    println!("cargo:rustc-env=VERSION={version}");

    // Re-run this build script if the VERSION file changes.
    println!("cargo:rerun-if-changed={}", version_path.display());
}
