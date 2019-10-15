# Fano CSRF Application

Example web application using which demonstrate how to use CSRF protection in Fano Framework.

This project is generated using [Fano CLI](https://github.com/fanoframework/fano-cli)
command line tools to help scaffolding web application using Fano Framework.

## Requirement

- [Free Pascal](https://www.freepascal.org/) >= 3.0
- Web Server (Apache, nginx)
- [Fano Web Framework](https://github.com/fanoframework/fano)


## Clone this repository

```
$ git clone git@github.com:fanofamework/fano-csrf.git --recursive
```

`--recursive` is needed so git also pull [Fano](https://github.com/fanoframework/fano) repository.

If you are missing `--recursive` when you clone, you may find that `vendor/fano` directory is empty. In this case run

```
$ git submodule update --init
```

## Copy configuration

```
$ ./tools/config.setup.sh
```

## Create directory for sessions

```
$ mkdir storages/sessions
$ chmod 775 storages/sessions
$ sudo chown [your user name]:[user where web server run] storages/sessions
```
Replace `[your user name]` and `[user where web server run]` with actual value. For example Apache in Debian by default using `www-data`.

## Build

Compile application.

```
$ ./build.sh
```

## Run

### Run with a webserver

If you have [Fano CLI](https://github.com/fanoframework/fano-cli) installed, run

```
$ sudo fanocli --deploy-fcgid=fano-csrf.fano
```

Otherwise you need to set virtual host manually. Please consult documentation of web server you use.

For example on Apache,

```
<VirtualHost *:80>
     ServerName fano-csrf.fano
     DocumentRoot /home/fano-csrf/public

     <Directory "/home/fano-csrf/public">
         Options +ExecCGI
         AllowOverride FileInfo
         Require all granted
         DirectoryIndex app.cgi
         AddHandler fcgid-script .cgi
     </Directory>
</VirtualHost>
```
On Apache, you will need to enable `mod_fcgid`.  For example, on Debian, this will enable `mod_fcgid` module.

```
$ sudo a2enmod fcgid
$ sudo systemctl restart apache2
```

Depending on your server setup, for example, if  you use `.htaccess`, add following code:

```
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ app.cgi [L]
</IfModule>
```
and put `.htaccess` file in same directory as `app.cgi` file (i.e., in `public` directory).

Content of `.htaccess` basically tells Apache to serve existing files/directories directly. For any non-existing files/directories, pass them to our application.

## Deployment

You need to deploy only executable binary and any supporting files such as HTML templates, images, css stylesheets, application config.
Any `pas` or `inc` files or shell scripts is not needed in deployment machine in order application to run.

So for this repository, you will need to copy `public`, `Templates`, `config`
and `storages` directories to your deployment machine. make sure that
`storages` directory is writable by web server.

## Known Issues

### Issue with GNU Linker

When running `build.sh` script, you may encounter following warning:

```
/usr/bin/ld: warning: public/link.res contains output sections; did you forget -T?
```

This is known issue between Free Pascal and GNU Linker. See
[FAQ: link.res syntax error, or "did you forget -T?"](https://www.freepascal.org/faq.var#unix-ld219)

However, this warning is minor and can be ignored. It does not affect output executable.

### Issue with unsynchronized compiled unit with unit source

Sometime Free Pascal can not compile your code because, for example, you deleted a
unit source code (.pas) but old generated unit (.ppu, .o, .a files) still there
or when you switch between git branches. Solution is to remove those files.

By default, generated compiled units are in `bin/unit` directory.
But do not delete `README.md` file inside this directory, as it is not being ignored by git.

```
$ rm bin/unit/*.ppu
$ rm bin/unit/*.o
$ rm bin/unit/*.rsj
$ rm bin/unit/*.a
```

Following shell command will remove all files inside `bin/unit` directory except
`README.md` file.

    $ find bin/unit ! -name 'README.md' -type f -exec rm -f {} +

`tools/clean.sh` script is provided to simplify this task.

### Windows user

Free Pascal supports Windows as target operating system, however, this repository is not yet tested on Windows. To target Windows, in `build.cfg` replace
compiler switch `-Tlinux` with `-Twin64` and uncomment line `#-WC` to
become `-WC`.

### Lazarus user

While you can use Lazarus IDE, it is not mandatory tool. Any text editor for code editing (Atom, Visual Studio Code, Sublime, Vim etc) should suffice.
