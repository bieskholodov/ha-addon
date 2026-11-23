# Home Assistant Add-on: Webmin

Webmin is a web-based interface for system administration and file management inside a Docker container.

## Installation

1. Add this repository to your Home Assistant Add-on Store.
2. Find the **Webmin** add-on and click **Install**.
3. Wait for the build process to complete (this may take a few minutes).

## Configuration

Before starting the add-on for the first time, go to the **Configuration** tab and set a secure password for the `root` user.

Example configuration:

```yaml
password: "MySuperSecretPassword123"
```

### Option: `password`

The password used to log in as the `root` user in the Webmin web interface. **Do not leave the default `changeme` password in production.**

## Usage

1. Start the add-on from the **Info** tab and check the **Log** tab to ensure it is running without errors.
2. Open your web browser and navigate to:
   ```text
   https://<YOUR_HOME_ASSISTANT_IP>:10000
   ```
   *(Make sure to use `https://`, not `http://`)*
3. Accept the browser security warning regarding the self-signed SSL certificate.
4. Log in with the following credentials:
   - **Username:** `root`
   - **Password:** *(the password you set in the Configuration tab)*

## Mapped Directories

This add-on has read/write access to the following Home Assistant directories:

- `/config` — Home Assistant configuration files
- `/ssl` — SSL certificates
- `/addons` — Local add-ons
- `/share` — Shared folder across add-ons
- `/backup` — Home Assistant backups
- `/media` — Local media files

## Limitations

Because Home Assistant OS runs add-ons in isolated Docker containers, Webmin only manages the environment and files inside its own container and the mapped directories listed above. Changes made to container system settings (such as network interfaces or system packages) will not affect the underlying Home Assistant OS host and will be reset when the add-on updates.
