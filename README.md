<h3 align="center">
    <img src="https://user-images.githubusercontent.com/30767528/80746783-b892d180-8b22-11ea-987a-34624c23ee65.png" alt="Logo" height="400">
</h3>

<h3 align="center">
    Beam up something. Instantly. Anonymously.
</h3>

<br/>

<p align="center">
  <a href="https://github.com/sponsors/Simonwep"><img
     alt="Support me"
     src="https://img.shields.io/badge/github-support-3498DB.svg"></a>
</p>

---
#### One-Command automated install

Beam.cafe can be installed using the following command:

```sh
curl -sSL https://raw.githubusercontent.com/dot-cafe/beam.cafe.sh/master/setup.sh | bash
```


#### Scripts

This repository contains shell scripts to set up beam.cafe on Ubuntu.

| Script | Description |
| ------ | ----------- |
| [`setup.sh`](setup.sh) | Installs all required dependencies on the target machine and sets up both front- and backend of [beam.cafe](http://beam.cafe). It's interactive and requires you to provide informations such as domain name etc. ([certbot](https://certbot.eff.org/)) |
| [`utils/update.backend.sh`](utils/update.backend.sh) | Used in CD to update the backend. |
| [`utils/update.frontend.sh`](utils/update.frontend.sh) | Used in CD to update the frontend. |
| [`tools/setup.brotli.sh`](scripts/setup.brotli.sh) | Utility script to set up the [brotli module](https://docs.nginx.com/nginx/admin-guide/dynamic-modules/brotli/) on nginx. Brotli is more dense than GZip and provides a higher compression rate. |

