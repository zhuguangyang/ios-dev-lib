# Setting $AYLA_BUILD_REPO and/or $AYLA_LIB_BRANCH environment variables
# will override to defaults for this release
AYLA_LIB_BRANCH="release/4.4.00"
AYLA_BUILD_REPO='https://github.com/AylaNetworks/iOS_AylaLibrary_Public.git'


ayla_lib_repo = `if [ $AYLA_BUILD_REPO ]; then echo $AYLA_BUILD_REPO; else touch ~/.bash_profile &&source ~/.bash_profile && echo $AYLA_BUILD_REPO; fi`
if ayla_lib_repo == "\n"
    ayla_lib_repo = AYLA_BUILD_REPO
    else
    ayla_lib_repo = ayla_lib_repo.delete!("\n")
end

branch_name = `. ~/.bash_profile && echo $AYLA_LIB_BRANCH`
if branch_name == "\n"
    branch_name=AYLA_LIB_BRANCH
    else
    branch_name = branch_name.delete!("\n")
    puts "\AYLA_LIB_BRANCH variable is currently set to \'#{branch_name}\'."
    
end
puts "Using \'#{branch_name}\' branch for Ayla Main Library.\n"

source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

pod 'iOS_AylaLibrary',
:git => "#{ayla_lib_repo}", :branch => "#{branch_name}"
#:git => 'https://github.com/AylaNetworks/iOS_AylaLibrary_Public.git', branch: 'master'
#:git => 'git@github.com:AylaNetworks/iOS_AylaLibrary_Public.git'
#:path => '../iOS_AylaLibrary_Public’