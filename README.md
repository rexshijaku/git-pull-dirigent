# Git Pull Dirigent

Git Pull Dirigent is a bash script which aims to automate the whole process of updating a Git repository in an advanced manner and one shot.

#### Main Features

  - Updates a Git repository
  - Installs or Updates php dependencies **if composer.json is affected** after pull
  - Installs or Updates node dependencies **if package.json was updated** after pull
  - Compiles Assets using Laravel Mix, **if any compileable file is affected** after pull
  - Offers **control over the processes** which can be executed
  
You can:
  - Specify what should be run and when should be run
 
### Usage

#### Requirments 
Depending on what you want to do with this script, it has different requirements.
##### php dependencies
 - To supervise php dependency management [Composer](https://getcomposer.org/download/) is required.
 - Your repository should contain composer.json file.

##### node dependencies
 - To manage node dependency management [NPM](https://getcomposer.org/download/) or [YARN](https://classic.yarnpkg.com/en/docs) is required.
 - Your repository should contain package.json file.
 
##### compiling assets
 - To conduct the complie process of your files requires [laravel-mix](https://laravel.com/docs/7.x/mix) must be included in node dependencies and to be configured properly.
 - Your repository should contain webpack.mix.js file. 
- To run mix you have to install [NPM](https://getcomposer.org/download/) or [YARN](https://classic.yarnpkg.com/en/docs).

 ### Choosing what to run
 Git Pull Dirigent's work is based on the digit combination **gpd_cmd** which can be found at the begining of the script. Every index in this command is reserved for a specific functionality. By default Git Pull Dirigent will run a digit combination like **11110** which will update your repository and subsequently it will check whether the **composer.json** was updated, if it does it will run **'composer install'** command, if not will do nothing. Similarly, it will run **'npm install'** command if **package.json** was updated. Finally, using **'npm run production'**  it will run all mix tasks by minifying output for production **if and only if** any of files which are set to be compiled **was changed**. What's good here is that we can have a control over this process and we can modify it by changing only a few variables. 
 Let's assume that instead of **npm** we want to use **yarn** to update our node dependencies, the only thing we should do is to **change the digit** in the second position (the index which is reserved for the type of PM) in the combination from **1** to **2**. In the same way, if we want to run **'composer update'** we can change only the first digit from **1** to **2**. Below is provided a table which helps to create combinations. If you don't want to run any of aforementioned tasks simply change its digit to **0**.

  ### Controlling when to execute
Git Pull Dirigent by default will run tasks asssigned to it only if their respective files get affected during update. For example, if package.json is changed, then gpd will update node dependencies, if not, gpd will not it will skip this process. We can have a control **when to run** jobs we specified to be done. This can be done by changing the last digit of combination. If this digit is set to **1** it will run always the commands which are specified, if it is **0** it will run them only if their files are changed.
 
### Creating combinations

Git Pull Dirigent can do diffent things by assigning different combinations to **gpd_cmd**. Instructions on how to use these commands are provided in the table below.

| ------ | -- COMPOSER  --| ----- JS PM ---- |  - JS PM CMD - | -  FILE COMPILE - |  ---- -- WHEN-- ------- |

| ------ | - install | update |  install | update  |  install | update  | - prod | dev | watch | always |- on update - |

| ------ |  --- 1 --- | --- 2 --- | ---- 1 --- | --- 2 ---  | --- 1 --- | --- 2 ----  |  -- 1 -- | - 2 - | -- 3 --  | --- 1 --- | --- -- 0 ------ |  

| ------ |  ---- ----  1  ---- ---- | ----- ---  1 ---- ---- | --- --- 1 --------   | ---   -- --- -- 1 -- --- ---- | --- --- - 0 --- --- ------- |

| ------ |  composer install  | --- ------  -----  npm install  --- --- ---    |  ---- run prod -------  |  -- on updates only - |

| ------ |  composer.json | --- --- --- --- package.json -- --- ---- ---   |  --  files to compile --- | ----------------------  |

In this table was described how **gpd_cmd=11110**, and what selected commands will do.

##### gpd_cmd examples:

- gpd_cmd=00000 -> will pull the changes and run nothing
- gpd_cmd=10000 -> will update php dependencies only if composer.json was changed
- gpd_cmd=10001 -> will update php dependencies always
- gpd_cmd=01101 -> will install node dependencies always
- gpd_cmd=01001 -> will do nothing, since script exits because in position 2 and 3 there is no job specified for npm 
- gpd_cmd=30000 -> will do nothing, script exists because there is a wrong command for composer

### Setting up the executable command

#### Linux(Ubuntu)
You can either set it to run as a global command or simply put in a project repository. To use it **as a global command** follow ensuing steps:
Open cmd and go to bin: 
```sh
$ cd /bin
```
create an file using your text editor, in my case nano:

```sh
$ nano gitpulldirigent  
```
add the content of this script and save it. After this make the file **executable**:
```sh
$ chmod +x gitpulldirigent  
```
your file is ready to run globaly. To **test** it, go to the root directory of your project
```sh
$ gitpulldirigent
```

#### Windows
Clone this script and  make sure it is placed in the projects root directory, makes sure you give the **read & execute permission** to it.
Right click in the main directory of your project and select **'Run Bash Here'** from the menu and run:
```sh
$ sh gitpulldirigent.sh
```
### Known issues
 - If files which are defined to be compiled by webpack mix contain modules (files) which are being included (imported) inside those files, changes in these imported module (files) will not trigger the necessary command.

### Todos

 - Testing more
 - Send gpd_cmd as parameter 
 - Extending functionality
 - Fix known issues

License
----

MIT
