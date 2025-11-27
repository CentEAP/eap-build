# JBoss Enterprise Application Platform (EAP) Builder

Build scripts for JBoss EAP 6, 7, or 8.  
Automate the assembly of JBoss Enterprise Application Platform (EAP) from source or binaries using simple shell scripts.  
Supports building with Maven, optional Docker support, and works across multiple operating systems.

---

## Table of Contents

- [Why Use This Builder?](#why-use-this-builder)
- [Supported Versions](#supported-versions)
- [Prerequisites](#prerequisites)
- [How to Use](#how-to-use)
- [Docker Build Instructions](#docker-build-instructions)
- [Supported Operating Systems](#supported-operating-systems)
- [Contributing](#contributing)
- [License](#license)

---

## Why Use This Builder?

- No need to manually download, configure or set up the EAP build environment.
- Fully automates the build and packaging process.
- Easily customizable and extensible for different EAP versions.
- Optional Docker support for containerized builds.

---

## Supported Versions


| EAP Version | Supported Builds                               |
|-------------|-----------------------------------------------|
| 8           | 8.0.0, 8.0.4                                  |
| 7           | 7.0.x: 7.0.0, 7.0.1, 7.0.2, 7.0.3, 7.0.4, 7.0.5, 7.0.6, 7.0.7, 7.0.8, 7.0.9 <br>
|             | 7.1.x: 7.1.0, 7.1.1, 7.1.2, 7.1.3, 7.1.4 <br>
|             | 7.2.x: 7.2.0, 7.2.1, 7.2.2, 7.2.3, 7.2.4, 7.2.5, 7.2.6, 7.2.7, 7.2.8, 7.2.9 <br>
|             | 7.3.x: 7.3.0, 7.3.1, 7.3.2, 7.3.3, 7.3.4 <br>
|             | 7.4.x: 7.4.0, 7.4.1, 7.4.2, 7.4.3, 7.4.4, 7.4.5, 7.4.6, 7.4.7, 7.4.8 |
| 6           | 6.1.1 <br>
|             | 6.2.x: 6.2.0, 6.2.1, 6.2.2, 6.2.3, 6.2.4 <br>
|             | 6.3.x: 6.3.0, 6.3.1, 6.3.2, 6.3.3 <br>
|             | 6.4.x: 6.4.0 - 6.4.25 |

---

## Prerequisites

- **Java**: JDK 8, 11, or 17 (depending on EAP version)
- **Maven**: 3.6.x or later
- **Git**: For cloning repositories
- **Docker**: (Optional) For container builds
- **Supported OS**: Linux, macOS, Windows (with Bash or WSL)

---

## How to Use

1. **Clone this repository:**
   ```bash
   git clone https://github.com/guifranchi/jboss-eap-builder.git
   cd jboss-eap-builder
   ```

2. **Run the build script:**
   ```bash
   ./build-eap.sh <version>
   ```
   Example:
   ```bash
   ./build-eap.sh 7.4.8
   ```

3. **Output:**
   The built EAP distribution will appear in the `output/` directory.

---

## Docker Build Instructions

1. **Build using Docker (optional):**
   ```bash
   docker build --build-arg EAP_VERSION=7.4.8 -t eap-builder:7.4.8 .
   ```

2. **Run the container:**
   ```bash
   docker run --rm -v $PWD/output:/output eap-builder:7.4.8
   ```

---

## Supported Operating Systems

- Linux (Tested: Ubuntu, CentOS, Fedora)
- macOS
- Windows (via WSL or Git Bash)

---

## Contributing

Pull requests and issues are welcome!  
Please fork the repository and submit your changes via a PR.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

**For more information, refer to the EAP documentation: [JBoss EAP Documentation](https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/)**
