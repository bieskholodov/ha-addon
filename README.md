# Home Assistant Add-on: Webmin

A web-based interface for system administration and file management inside a Home Assistant container.

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armv7 Architecture][armv7-shield]

## About

[Webmin](https://webmin.com) is a web-based system configuration tool for Unix-like systems. This add-on runs Webmin inside an isolated Docker container on Home Assistant OS, allowing you to conveniently manage mounted Home Assistant directories (`/config`, `/share`, `/ssl`, `/addons`, `/backup`, `/media`) via a browser.

> **Note:** Because Home Assistant OS uses isolated containers, Webmin in this add-on manages the container environment and mapped folders rather than the underlying host operating system settings.

## Installation

1. Navigate to **Settings** -> **Add-ons** -> **Add-on Store** in your Home Assistant instance.
2. Click the three dots in the top right corner and select **Repositories**.
3. Add the URL of this repository:
   ```text
   https://github.com
   ```
4. Refresh the store page, find **Webmin** under your repository section, and click **Install**.

## Configuration

Before starting the add-on, go to the **Configuration** tab and set a strong password for the `root` user:

```yaml
password: "your_secure_password"
```

### Options

| Option | Type | Description |
| :--- | :--- | :--- |
| `password` | `password` | Password for the `root` user to log into the Webmin interface (default: `changeme`). |

## Usage

1. Start the add-on from the **Info** tab.
2. Open your browser and navigate to `https://<YOUR_HOME_ASSISTANT_IP>:10000`.
3. Accept the self-signed SSL certificate warning in your browser.
4. Log in using the username `root` and the password you configured.

[aarch64-shield]: https://shields.io
[amd64-shield]: https://shields.io
[armv7-shield]: https://shields.io
