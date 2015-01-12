# stormpath-mod-authnz-external

Use Stormpath to secure the Apache web server!

The instructions below are specific to Ubuntu/Debian, but the steps are mostly the same for \*nix installations (albeit with different commands - `yum` instead of `apt-get`, etc.).

1. Ensure Apache 2.4 or later is installed:

    ```bash
    sudo apt-get install apache2
    ```
2.  Ensure the Apache `mod_authnz_external` and `pwauth` modules are installed:

    ```bash
    sudo apt-get install libapache2-mod-authnz-external pwauth
    ```

3.  Ensure these modules are enabled:

    ```bash
    sudo a2enmod authnz_external
    sudo a2enmod pwauth
    ```

4.  Download the `stormpath.sh` shell script that will be executed by `mod_authnz_external` during a login attempt:

    ```bash
    curl -O https://raw.githubusercontent.com/stormpath/stormpath-mod-authnz-external/master/stormpath.sh
    ```

5.  Ensure the downloaded file is executable by the apache2 system user (e.g. `www-data` on Ubuntu).  You will also likely want to assign group ownership to the apache system user as well.  For example:

    ```bash
    sudo chgrp www-data stormpath.sh
    chmod ug+x stormpath.sh
    ```

6.  Update your host (or virtual host) configuration to reference the `stormpath.sh` authentication script.  For example, assuming a host `foo.com`:

    ```apache
    <VirtualHost *:443>

        ServerName foo.com
        ServerAdmin webmaster@foo.com

        ErrorLog ${APACHE_LOG_DIR}/foo.com.error.log
        CustomLog ${APACHE_LOG_DIR}/foo.com.access.log combined

        DocumentRoot /var/www/vhosts/foo.com

        DefineExternalAuth stormpath pipe "/PATH/TO/stormpath.sh /PATH/TO/YOUR/stormpath/apiKey.properties YOUR_STORMPATH_APPLICATION_HREF"

        <Directory /var/www/vhosts/foo.com/downloads>
            AuthType Basic
            AuthName "Authenticated Users Only"
            AuthBasicProvider external
            AuthExternal stormpath
            require valid-user
        </Directory>

    </VirtualHost>
    ```

    where:

    * `/PATH/TO/stormpath.sh` is the path on your local filesystem to the `stormpath.sh` file you downloaded
    * `/PATH/TO/YOUR/stormpath/apiKey.properties` is the path on your local filesystem to your personal stormpath `apiKey.properties` file.  This *must* begin with `/`, i.e. it must be a fully qualified path to a file on your operating system.  It must also be readable by the apache system user (e.g. `www-data`)
    * `YOUR_STORMPATH_APPLICATION_HREF` is the fully qualified `href` of your application record in Stormpath for which users must authenticate.

In the above example, the `require valid-user` line ensures that only authenticated users of the referenced Stormpath application may access anything in the `/var/www/vhosts/foo.com/downloads` directory.
