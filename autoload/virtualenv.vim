if has('python3')
    python3 import sys, vim
    python3 if vim.eval('expand("<sfile>:p:h")') not in sys.path: sys.path.append(vim.eval('expand("<sfile>:p:h")'))
    python3 import pyvenv
endif
if has('python')
    python import sys, vim
    python if vim.eval('expand("<sfile>:p:h")') not in sys.path: sys.path.append(vim.eval('expand("<sfile>:p:h")'))
    python import pyvenv
endif

function! virtualenv#activate(...)

    if exists('b:venv_loaded') && b:venv_loaded == get(g:, 'virtualenv_name', '')
        if exists("*airline#extensions#virtualenv#update")
               call airline#extensions#virtualenv#update()
        endif
        return
    endif
    call virtualenv#deactivate()
    let name   = a:0 > 0 ? a:1 : ''
    let silent = a:0 > 1 ? a:2 : 0
    let env_dir = ''
    if len(name) == 0
        let pipenv = trim(matchstr(system('which pipenv > /dev/null && pipenv --venv'), '^/.\+'))
        if len(pipenv)
            let env_dir = pipenv
            let full_env_name = fnamemodify(env_dir, ":t")
            let last_hifen = strridx(full_env_name, '-')
            let env_name = full_env_name[0:last_hifen - 1]

            let name = env_name
        endif
    else
        let env_dir = g:virtualenv_directory.'/'.name
    endif

    "Couldn't figure it out, so DIE
    if !isdirectory(env_dir)
        if !silent
            echoerr "No virtualenv could be auto-detected and activated."
        endif
        return
    endif

    let bin = env_dir.(has('win32')? '/Scripts': '/bin')

    let s:prev_path = $PATH

    if has('python')
        python pyvenv.activate(vim.eval('l:env_dir'))
    endif
    if has('python3')
        python3 pyvenv.activate(vim.eval('l:env_dir'))
    endif

    let g:virtualenv_name = name
    let $VIRTUAL_ENV = env_dir

    if exists("*airline#extensions#virtualenv#update")
           call airline#extensions#virtualenv#update()
    endif

    let b:venv_loaded = g:virtualenv_name
endfunction

function! virtualenv#deactivate()
    if has('python')
        python pyvenv.deactivate()
    endif
    if has('python3')
        python3 pyvenv.deactivate()
    endif

    unlet! g:virtualenv_name

    let $VIRTUAL_ENV = '' " can't delete parent variables

    if exists('s:prev_path')
        let $PATH = s:prev_path
    endif

    if exists("*airline#extensions#virtualenv#update")
           call airline#extensions#virtualenv#update()
    endif
endfunction

function! virtualenv#list()
    for name in virtualenv#names('')
        echo name
    endfor
endfunction

function! virtualenv#statusline()
    if exists('g:virtualenv_name')
        return substitute(g:virtualenv_stl_format, '\C%n', g:virtualenv_name, 'g')
    else
        return ''
    endif
endfunction

function! virtualenv#names(prefix)
    let venvs = []
    for dir in split(glob(g:virtualenv_directory.'/'.a:prefix.'*'), '\n')
        if !isdirectory(dir)
            continue
        endif
        let fn = dir.(has('win32')? '/Scripts': '/bin').'/activate'
        if !filereadable(fn)
            continue
        endif
        call add(venvs, fnamemodify(dir, ':t'))
    endfor
    return venvs
endfunction
