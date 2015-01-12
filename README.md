# stormpath-mod-authnz-external
Using Stormpath to secure the Apache web server

1. Ensure Apache 2.4 or later is installed:

    ```bash
    sudo apt-get install apache2
    ```
2.  Ensure the `mod_authnz_external` and `pwauth` modules are installed:

    ```bash
    sudo apt-get install libapache2-mod-authnz-external pwauth
    ```

3.  Ensure the modules are enabled:

    ```bash
    sudo a2enmod authnz_external
    sudo a2enmod pwauth
    ```

4.  Update your host (or virtual host) configuration to reference the `stormpath.sh` authentication script (available in this git repo as `stormpath.sh`).  For example, assuming a host `foo.com`:

    ```apache
    <VirtualHost *:80>

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

    * `/PATH/TO/stormpath.sh` is the path on your local filesystem to the `stormpath.sh` file you downloaded from this git repository
    * `/PATH/TO/YOUR/stormpath/apiKey.properties` is the path on your local filesystem to your personal stormpath `apiKey.properties` file.  This *must* begin with `/`, i.e. it must be a fully qualified path to a file on your operating system.
    * `YOUR_STORMPATH_APPLICATION_HREF` is the fully qualified `href` of your application in href that your users must have access to.

In the above example, only authenticated users may access anything in the `/var/www/vhosts/foo.com/downloads` directory.
