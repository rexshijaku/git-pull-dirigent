#!/bin/bash

#---------------------------------------------------------------------------------------------------------------------------------------------------
#	Git Pull Dirigent
#---------------------------------------------------------------------------------------------------------------------------------------------------

#====================================================================================================================================================
#		
#		
#		   NAME:	Git Pull Dirigent
#		PURPOSE:	Automate post-pull tasks
#		 AUTHOR: 	Rexhep Shjaku, https://github.com/rexshijaku
#			URL:	https://github.com/rexshijaku/gitpulldirigent
#	    CREATED: 	March - April 2020
#	LAST UPDATE:	2nd of April  2020
#	REQUIRMENTS:	Depends on what you want to run, read the next section.
#	
#
#====================================================================================================================================================

#====================================================================================================================================================
#		
#		          	
#		Based on what you want to run all the main gpd functionality is listed below:
#	  
#
#			I. 		Installs/Updates php dependencies if composer.json is affected after pull
#					REQUIRMENTS   : composer
#
#		   II. 		Instals/Updates node dependencies if package.json was changed after pull
#		   		    Packet Manager: NPM or YARN	
#					REQUIRMENTS   : npm or yarn 
#				
#		  III.		Compiles Assets using Laravel Mix, if any file is affected after pull
#					Packet Manager: NPM or YARN	
#					Options		  : Run all Mix tasks and minify output
#								  : Run all Mix tasks
#								  : Watching Assets For Changes
#					REQUIRMENTS   : laravel-mix (which requires npm or yarn)
#
#
#		To create gpd_cmd combination which tells gpd what to run, when to run and how to run, 
#				check the full documentation in https://github.com/rexshijaku/gitpulldirigent.
#
#
#====================================================================================================================================================

#====================================================================================================================================================
#
#
#		gpd_cmd combination example : 11110
#
#						translation : first update current branch by running 'git pull'
#									: after pull
#									: if composer.json was changed run 'composer install'
#									: chose npm
#									: if package.json was changed run 'npm install'
#									: if any file was specified to be compiled in webpack.mix.js is changed run 'npm run production'
#
#
#				further explanation : if you change the last digit of combination to 1, 
#									  gpd will run commands even their corresponding files were not changed
#
#									: if you change the first digit of combination to 0, 
#									  gpd will not consider php dependencies
#
#				 					: if you change the second digit of combination to 2, 
#									  gpd will run 'composer update' command instead of 'composer install'
#
#
#====================================================================================================================================================

gpd_cmd=11110 #check documentation in github if you need to change this combination
gpd_ask=1 #set this 1 if you want to confirm what will be executed 

#region [job tracking]
#tracks jobs which are set to be done, if any job fails then all remaining jobs will be suggested to be done in next run
#if lock is disabled then it will not suggest to re-run previously failed tasks
#by defult it is enabled
gpd_check_lckd=1 # when equals to 1 dirigent will check whether there is any previously not completed job
gpd_lckcmds=00000 #default value
gpd_lck_file="gitpulldirigent.lock" #lock file name
#endregion [job tracking]

#region [command indexes] in gpd_cmd
gpd_cmps_indx=0
gpd_pckt_indx=1
gpd_pckj_indx=2
gpd_wpck_indx=3
gpd_rnaw_indx=4
#endregion

#by default allow any error to terminate the running script (this changes in runtime)
set -e

gdpPrint(){
	echo "git pull dirigent : $1"
}

#region [check if script is ready to be executed]
gpdFillCmds() {
	gpd_cmps=${gpd_cmd:$gpd_cmps_indx:1}
	gpd_pckt=${gpd_cmd:$gpd_pckt_indx:1}
	gpd_pckj=${gpd_cmd:$gpd_pckj_indx:1}
	gpd_wpck=${gpd_cmd:$gpd_wpck_indx:1}
	gpd_rnaw=${gpd_cmd:$gpd_rnaw_indx:1}
}


gpdInvalidCommand(){
	gdpPrint "invalid digit at position $1 of [$gpd_cmd]"
}

#exists the script by giving a reason (sent as first parameter)
gpdExitScript(){
	gdpPrint "exiting script... | reason : $1!"
	exit
}

gpdCheckCommands(){

gpdFillCmds
gdpPrint "selected command combination to run: $gpd_cmd"
gdpPrint "validating command combination..."

#region [checks whether any combination was given]
if [[ ${#gpd_cmd} -lt 5 || ${gpd_cmd:0:4} = 0000 ]]; then
	gpdExitScript "correct digit combination was not provided"
fi

reg='^[0-9]+$'
if ! [[ $gpd_cmd =~ $reg ]] ; then
	gpdExitScript "combination should only contain digits" >&2; exit 1
fi
#endregion [checks whether any combination was given]

#region [check composer]
if ! [[ $gpd_cmps -ge 0 && $gpd_cmps -le 2 ]]; then
	gpdExitScript "invalid digit for composer! $(gpdInvalidCommand $gpd_cmps_indx)"
else
	if ! hash composer 2>/dev/null; then
	    gpdExitScript "composer command was not found!"
	fi
fi
#endregion [check composer]

#region [check if js packages can be installed/updated]
if [[ $gpd_pckj -eq 1 || $gpd_pckj -eq 2 ]]; then
   	if ! [[ $gpd_pckt -eq 1 || $gpd_pckt  -eq 2 ]]; then
   		gpdExitScript "in order to install/update dependencies you must specify a valid js packet manager! $(gpdInvalidCommand $gpd_pckt_indx)"
   	fi	
elif [[ $gpd_pckj -ne 0 ]]; then
	   	gpdExitScript "invalid digit for action type for node packer manager! $(gpdInvalidCommand $gpd_pckj_indx)"
fi
#endregion [check if packages can be installed/updated]

#region [checks if compile can be done]
if [[ $gpd_wpck -ge 1 && $gpd_wpck -le 3 ]]; then
   	if ! [[ $gpd_pckt -eq 1 || $gpd_pckt  -eq 2 ]]; then
   		gpdExitScript "in order to compile your assets, you must specify a valid js packet manager! $(gpdInvalidCommand $gpd_pckt_indx)"
   	fi	
elif [[ $gpd_wpck -ne 0 ]]; then
   		gpdExitScript "invalid digit for compile! $(gpdInvalidCommand $gpd_wpck_indx)"
fi
#endregion [checks if compile can be done]

#region [check run type]
if ! [[ $gpd_rnaw -eq 0 || $gpd_rnaw -eq 1 ]]; then 
	 gpdExitScript "last digit combination should either be one or zero! $(gpdInvalidCommand $gpd_rnaw_indx)"
fi	
#region [check run type]


#checks [check if js package manager is valid and it has a job to perfrom]
if [[ $gpd_pckt -eq 1 ]] || [[ $gpd_pckt  -eq 2 ]]; then
	if [[ $gpd_pckj -ne 1 && $gpd_pckj -ne 2 ]]  && [[ $gpd_wpck -lt 1 || $gpd_wpck -gt 3 ]]; then
		if [[ gpd_pckt -eq 1 ]];then
			gpdExitScript "npm's job was not specified!"
		else
			gpdExitScript "yarn's job was not specified!"
		fi	
	else
		if [[ gpd_pckt -eq 1 ]]; then
			if ! hash npm 2>/dev/null; then
			    gpdExitScript "npm command was not found!"
			fi
		else
			if ! hash yarn 2>/dev/null; then
			    gpdExitScript "yarn command was not found!"
			fi
		fi	
	fi
elif [[ $gpd_pckt -ne 0 ]]; then
	gpdExitScript "invalid digit for js packet manager!"
fi
#endregion [check if js package manager is valid and it has a job to perfrom]

gdpPrint "valid combination..."

}

#gpdPreviouslyUnfinishedTasks
#gdp checks whether previosuly-unfinished tasks should be re-run again
#gdp translates combination in order to notify user what will try to do
gpdPreviouslyUnfinishedTasks(){

if [[ $gpd_check_lckd -eq 1 ]]; then
	gdpPrint "checking if $gpd_lck_file exists..."
	if test -f $gpd_lck_file; then

		gdpPrint "$gpd_lck_file exists..."
	 	lckd_cmds=$(head -n 1 $gpd_lck_file) #read content (first line)
	 	tmp=$gpd_cmd 
		gpd_cmd=$lckd_cmds #asssing locked command to global cmd variable in order to use its functionality, 
						   #after previous-jobs are finshed we re-assign back its original value
		gpdFillCmds

	 	msg_lck=""
	 	if [[ $gpd_cmps -ne 0 ]]; then
			msg_lck+=" (1) composer"
			if [[ $gpd_cmps -eq 1 ]]; then
				msg_lck+=" will install"
			elif [[ $gpd_cmps -eq 2 ]]; then
				msg_lck+=" will update"
			fi
			msg_lck+=" packages that are listed in composer.json"
		fi	

		#region [node packet manager question building]
		if [[ $gpd_pckt -ne 0 ]]; then

			if [[ $gpd_cmps -ne 0 ]]; then
				msg_lck+=" (2)"
			else
				msg_lck+=" (1)"	
			fi	
			
			if [[ $gpd_pckt -eq 1 ]]; then
				msg_lck+=" npm"
			elif [[ $gpd_pckt -eq 2 ]]; then
				msg_lck+=" yarn"
			fi
			msg_lck+=" will"

			if [[ $gpd_pckj -ne 0 ]]; then

				if [[ $gpd_pckj -eq 1 ]]; then
					msg_lck+=" install"
				elif [[ $gpd_pckj -eq 2 ]]; then
					msg_lck+=" update"
				fi
				msg_lck+=" dependencies that are listed in package.json"

				if [[ $gpd_wpck -ne 0 ]]; then
					msg_lck+=" and"
					if [[ $gpd_cmps -ne 0 ]]; then
						msg_lck+=" (3)"
					else
						msg_lck+=" (2)"	
					fi	
					msg_lck+=" will also"
				fi	
			fi 
			#endregion [node packet manager question building]

			#region [webpack question building]
			if [[ $gpd_wpck -ne 0 ]]; then
				if [[ $gpd_wpck -eq 1 ]]; then
					msg_lck+=" run all mix tasks by minifying output for production"
				elif [[ $gpd_wpck -eq 2 ]]; then
					msg_lck+=" run all mix tasks for development"
				elif [[ $gpd_wpck -eq 3 ]]; then
					msg_lck+=" watch all relevant files for changes"
				fi
			fi 
			#endregion [webpack question building]
		fi

		if [ "$msg_lck" == "" ];then
		   gdpPrint "the jobs in $gpd_lck_file are not valid!"
		   gdpRemoveLock
		   gpd_cmd=$tmp
		   return 0
		fi

		#ask if previous-unfinished jobs should be run now
		gdpPrint "the last run of this command was not finished properly, do you want to re-run the following unfinished jobs : $msg_lck"
		if [[ $gpd_ask -eq 1 ]]; then
			read -p "git pull dirigent : (y/n)? " cnt
			if [ "$cnt" = "y" ]; then
				gpdCreateLock
				gpdRunAll
			fi
		fi

		#after user refused to run previously-unfinished jobs or accepted to do it and all jobs finished successfully
		gdpRemoveLock
		gpd_cmd=$tmp #reassign the original combination
	else 
		gdpPrint "$gpd_lck_file not found..."	
	fi
fi #end check lock file statement
}	
#end of gpdPreviouslyUnfinishedTasks

#gdp translates combination in order to notify user what will try to do
gpdTranslateCommands(){

translated=""

if [[ $gpd_cmps -ne 0 ]]; then
		translated+=" (2) composer"
	if [[ $gpd_cmps -eq 1 ]]; then
		translated+=" will install"
	elif [[ $gpd_cmps -eq 2 ]]; then
		translated+=" will update"
	fi
	translated+=" packages that are listed in composer.json"

	if [ $gpd_rnaw -eq 1 ]; then 
		translated+=" [even this file is not updated after pull"
	else
		translated+=" [only if this file is updated after pull]"
	fi	
fi

if [[ $gpd_pckt -ne 0 ]]; then

	if [[ $gpd_cmps -ne 0 ]]; then
		translated+=" (3)"
	else
		translated+=" (2)"	
	fi	

	if [[ $gpd_pckt -eq 1 ]]; then
		translated+=" npm"
	elif [[ $gpd_pckt -eq 2 ]]; then
		translated+=" yarn"
	fi
	translated+=" will"

	#node packet manager question building
	if [[ $gpd_pckj -ne 0 ]]; then

		if [[ $gpd_pckj -eq 1 ]]; then
			translated+=" install"
		elif [[ $gpd_pckj -eq 2 ]]; then
			translated+=" update"
		fi
		translated+=" dependencies that are listed in package.json"

		if [ $gpd_rnaw -eq 1 ]; then 
			translated+=" [even if this file is not updated after pull]"
		else
			translated+=" [only if this file is updated after pull]"
		fi	

		if [[ $gpd_wpck -ne 0 ]]; then
			translated+=" and"
			if [[ $gpd_cmps -ne 0 ]]; then
				translated+=" (4)"
			else
				translated+=" (3)"	
			fi	
			translated+=" will also"
		fi	
	fi
	#end ofnode packet manager question building

	#webpack question building
	if [[ $gpd_wpck -ne 0 ]]; then
		if [[ $gpd_wpck -eq 1 ]]; then
			translated+=" run all mix tasks by minifying output for production"
		elif [[ $gpd_wpck -eq 2 ]]; then
			translated+=" run all mix tasks for development"
		elif [[ $gpd_wpck -eq 3 ]]; then
			translated+=" watch all relevant files for changes"
		fi
		if [ $gpd_rnaw -eq 1 ]; then 
			translated+=" [even any of files which are set to compile (in webpack.mix.js) was not updated]"
		else
			translated+=" [only if any of files which are set to compile (in webpack.mix.js) was updated]"
		fi	
	fi
	#end of webpack question building
fi

gdpPrint "dirigent will run the following tasks: (1) git will pull changes from the upstram branch $translated"

if [[ $gpd_ask -eq 1 ]]; then
	read -p "git pull dirigent : continue (y/n)? " cnt
	if [ "$cnt" = "n" ]; then
		exit
	fi
fi
}

#endregion [check if script is ready to be executed]


gpdCreateLock(){

	gdpPrint "creating $gpd_lck_file"
	gpd_lckcmds=$gpd_cmd
	echo $gpd_lckcmds >> $gpd_lck_file
}

gdpRemoveLock(){

	if test -f $gpd_lck_file; then
		gdpPrint "removing $gpd_lck_file"
		rm $gpd_lck_file
		gdpPrint "$gpd_lck_file was removed"
	fi	
}

#when a job starts it is registered in lock file, and when it ends it is updted to 0 (in that file)
gpdSaveCommandState()
{
	#$1 is the index of comaand, $2 is the value of command which was set in gpd_cmd 
	gpd_lckcmds="${gpd_lckcmds:0:$1}$2${gpd_lckcmds:$1+1}"
	> $gpd_lck_file #reset file content 
 	echo $gpd_lckcmds >> $gpd_lck_file #add line
 	#gdpPrint "saving command current state $gpd_lckcmds..."
}

gpdRunComposer(){

	set -e
	gdpPrint "working on php dependencies..."
	if test -f "composer.json"; then
		if [ $gpd_cmps = 1 ]; then
			gdpPrint "running composer install..."
			composer install
		elif [ $gpd_cmps = 2 ]; then
			gdpPrint "running composer update..."
			composer update
		fi
	else
		gdpPrint "composer.json was not found!"
	fi
	gdpPrint "working on php dependencies finished..."
	gpdSaveCommandState $gpd_cmps_indx 0 #means execution was completed
}

gpdRunJsPM(){

	set -e
	gdpPrint "working on js dependencies..."
	if test -f "package.json"; then
		if [[ $gpd_pckt -eq 1 ]]; then 
			if [[ $gpd_pckj -eq 1 ]]; then
				gdpPrint "running npm install..."
				npm install
			elif [[ $gpd_pckj -eq 2 ]]; then
				gdpPrint "running npm update..."
				npm update
			fi
		elif [[ $gpd_pckt -eq 2 ]]; then
			if [[ $gpd_pckj -eq 1 ]]; then
				gdpPrint "running yarn install..."
				yarn install
			elif [[ $gpd_pckj -eq 2 ]]; then
				gdpPrint "running yarn upgrade..."
				yarn upgrade
			fi
		fi	
	else
		gdpPrint "package.json was not found!"
	fi
	gdpPrint "working on js dependencies finished..."
	gpdJsDependenciesDone
	
}

gpdCompileAssets(){
	
	set -e
	gdpPrint "working on compiling assets..."
	gpdSaveCommandState $gpd_pckt_indx $gpd_pckt #if fails then next run will remember what packet manager was used

	if test -f "webpack.mix.js"; then
		if [[ $gpd_pckt -eq 1 ]]; then
			if [[ $gpd_wpck = 1 ]]; then
				gdpPrint "running npm run production..."
				npm run production
			elif [[ $gpd_wpck = 2 ]]; then
				gdpPrint "running npm run development..."
				npm run dev
			elif [[ $gpd_wpck = 3 ]]; then
				gdpPrint "running npm run watch..."
				npm run watch
			fi
		elif [[ $gpd_pckt -eq 2 ]]; then
			if [[ $gpd_wpck = 1 ]]; then
				gdpPrint "running yarn run production..."
				yarn run prod
			elif [[ $gpd_wpck = 2 ]]; then
				gdpPrint "running yarn run development..."
				yarn run dev
			elif [[ $gpd_wpck = 3 ]]; then
				gdpPrint "running yarn run watch..."
				yarn run watch
			fi
		fi	
	else
		gpdCompileAssets "webpack.mix.js is missing!"
	fi	
	gdpPrint "working on compiling assets finished..."
	gpdComplieDone #means execution was completed	
}

gpdRunAll(){

  	if [ $gpd_cmps -ne 0 ]; then 
  		gpdRunComposer
  	fi
  	if [ $gpd_pckj -ne 0 ]; then 
  		gpdRunJsPM
  	fi	
  	if [ $gpd_wpck -ne 0 ]; then 
  		gpdCompileAssets
  	fi	
}

gpdComplieDone(){	#means execution was completed

	gpdSaveCommandState $gpd_pckt_indx 0
	gpdSaveCommandState $gpd_wpck_indx 0 
}

gpdJsDependenciesDone(){ #means execution was completed
	gpdSaveCommandState $gpd_pckt_indx 0 
	gpdSaveCommandState $gpd_pckj_indx 0 
}

gpdInitialize()
{
	gpdPreviouslyUnfinishedTasks
	gpdCheckCommands
	gpdTranslateCommands
	gpdCreateLock
}

gpdDirigePull(){
	
	gpdInitialize

	set +e #currently set this to get if active branch is tracking an upstram branch, otherwise it will throw error
	current_branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
	upstream_branch=$(git rev-parse --abbrev-ref $current_branch@{upstream} 2>/dev/null) 
	

	if [[ $? == 0 ]]; then #remote tracking branch found

		gdpPrint "$current_branch is tracking $upstream_branch..."
	    updated_files=$(git fetch && git diff --name-only $current_branch $upstream_branch);
		upd_files_arr=(${updated_files}) #conv to arr
		updtd_file_lngth="${#upd_files_arr[@]}"

	    if [[ $updtd_file_lngth > 0 ]]; then
			gdpPrint "there are updated files on the remote branch! pulling the changes..."
			if git pull; then
				
				#region composer
				if [[ $gpd_cmps -ne 0 ]]; then 
					if [[ " ${upd_files_arr[@]} " =~ " composer.json " ]]; then
					  	  	gdpPrint "composer.json was updated..."
							gpdRunComposer
					else
			        	gdpPrint "composer.json was not updated"
			        	
			        	if [ $gpd_rnaw -eq 1 ]; then 
				      		gpdRunComposer
				      	else
				      		gpdSaveCommandState $gpd_cmps_indx 0 #consider completed
				      	fi	
	            	fi 
	            fi
	            #endregion composer

		        #region node packet managers
		        if [ $gpd_pckj -ne 0 ]; then
		        	if [[ " ${upd_files_arr[@]} " =~ " package.json " ]]; then
		        		gdpPrint "package.json was updated..."
		        		gpdRunJsPM
					else
			        	gdpPrint "package.json was not changed"
			        
			        	if [ $gpd_rnaw -eq 1 ]; then 
				      		gpdRunJsPM
				      	else
				      		gpdJsDependenciesDone #consider completed	
				      	fi	
	            	fi 
				fi
				#endregion node packet managers

				#region webpack - laravel mix
				if [ $gpd_wpck -ne 0 ]; then 
					gdpPrint "analyzing if any file which is set to be compiled (in webpack.mix.js) was updated..."	
					if test -f "webpack.mix.js"; then
					 	mthds=("js"
						"sass"
						"less"
						"stylus"
						"react"
						"copy"
						"copyDirectory"
						)
					 	found=false
						for mthd in "${mthds[@]}"; do 

							if ! grep -q "$mthd(" "webpack.mix.js"; then
								continue
							fi	
							grepped=$(grep -rnw 'webpack.mix.js' -e "$mthd(")
							readarray -t y <<<"$grepped" #convert to array of lines
							for line in "${y[@]}"; do #each line find src files
								while [[ $line == *"("* ]]
								do
							 		line=${line#*(}
									substr=$(echo $line| cut -d',' -f 1)
								    file_=${substr:1}
								    file_=${file_:0:-1}
								    gdpPrint "checking if $file_ was updated..."
								    if [[ " ${upd_files_arr[@]} " =~ " $file_ " ]]; then	
						              gdpPrint "$file_ was updated!"
						              gdpPrint "gpd will not analyze further"
						              gpdCompileAssets
						              found=true
						              break
						            else
						              gdpPrint "$file_ was not updated!" 
							        fi
								done #end of while loop
								if [[ $found == true ]]; then	
								 	break	
								fi			
							done #end of for loop
							if [[ $found == true ]]; then	
								break	
							fi			
						done #end of loop
						if [[ $found == false ]]; then
						   gdpPrint "no file which is set to get compiled (in webpack.mix.js) was updated!"	
						   if [[ $gpd_rnaw -eq 1 ]]; then
							   gpdCompileAssets
						   else
						   	   gpdComplieDone #consider completed
						   fi
						fi	
					 else
					 	gpdCompileAssets "webpack.mix.js is missing!"
					 fi # end of if statment which checks if webpack should run
		        fi
		        #endregion webpack
		    fi
	    else
		    gdpPrint "$current_branch is already up to date!"
			if [[ $gpd_rnaw -eq 1 ]]; then
				gdpPrint 'running tasks since it was set to run them when there is not any update...'
				gpdRunAll
		  	fi	
	    fi
	else
	    gdpPrint '$current_branch has no upstream branch!'
	 	if [[ $gpd_rnaw -eq 1 ]]; then
	 		gdpPrint 'running tasks since it was set to run them when there is not any update...'
			gpdRunAll
		fi	
	fi
	gdpRemoveLock
	gdpPrint "dirigent diriged successfully..."
}
gpdDirigePull