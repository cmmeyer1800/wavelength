# Wavelength

A super simple manager for global uv virtual environments.

## Who?

Do you want the speed and modernity of UV with the nice CLI options and environment management of conda? Wavelength is for you.

## Installation

uv must be installed:

https://docs.astral.sh/uv/getting-started/installation/

### Easy install

```bash
curl -LsSf https://github.com/cmmeyer1800/wavelength/releases/latest/download/install.sh | sh
```

### From source

```bash
git clone https://github.com/cmmeyer1800/wavelength
cd wavelength
./local_install.sh ./wl.sh
```

## Post install

After running the installer script, do not forget to add the following to your `.<shell>rc` file:

```bash
source ~/.wavelength/wl.sh
```

## Updating

Run `wl update` to check for and install the latest release.
