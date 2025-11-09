fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'pallesa'

client_script {
    'client/main.lua',
    'client/functions.lua',
    'client/modules/*.lua'
}

shared_script {
    '@ox_lib/init.lua',
    'common/main.lua'
}

dependency {
    'ox_lib'
}

ui_page "build/index.html"
-- ui_page 'http://localhost:3000/'

files {
    'build/**/*'
}