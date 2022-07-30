if exists("loaded_cmdalias")  | finish  | endif

let loaded_cmdalias = 1

let s:save_cpo = &cpo  | set cpo&vim

if !exists('g:alias_prefix')  | let g:alias_prefix = 'verbose debug silent redir'  | endif

com!  -nargs=+ Alias      :call CmdAlias(<f-args>)
com!  -nargs=* UnAlias    :call UnAlias(<f-args>)
com!  -nargs=* Aliases    :call <SID>Aliases(<f-args>)

if ! exists('s:aliases')  | let s:aliases = {}  | en

" Define a new command alias.
fun! CmdAlias(lhs, ...)
    let lhs = a:lhs
    if lhs !~ '^\w\+$'
        echohl ErrorMsg | echo 'Only word characters are supported on <lhs>' | echohl NONE
        return
    en
    if a:0 > 0
        let rhs = a:1
    el
        echohl ErrorMsg | echo 'No <rhs> specified for alias' | echohl NONE
        return
    en

    if has_key(s:aliases, rhs)
        echohl ErrorMsg | echo "Another alias can't be used as <rhs>" | echohl NONE
        return
    en

    if a:0 > 1
        let flags = join(a:000[1:], ' ') . ' '
    el
        let flags = ''
    en

    exe   'cnoreabbr <expr> ' . flags . a:lhs .
        \ " <SID>ExpandAlias('" . lhs . "', '" . rhs . "')"
    let s:aliases[lhs] = rhs
endf

fun! s:ExpandAlias(lhs, rhs)
    if getcmdtype() == ":"
        " Determine if we are at the start of the command-line.
        " getcmdpos() is 1-based.
        let partCmd = strpart(getcmdline(), 0, getcmdpos())
        let prefixes = ['^'] + map(split(g:alias_prefix, ' '), '"^".v:val."!\\?"." "')
        for prefix in prefixes
            if partCmd =~ prefix . a:lhs . '$'  | return a:rhs  | en
        endfor
    en
    return a:lhs
endf

fun! UnAlias(...)
    if a:0 == 0
        echohl ErrorMsg | echo "No aliases specified" | echohl NONE
        return
    en

    let aliasesToRemove = filter(
                            \ copy(a:000),
                            \ 'has_key(s:aliases, v:val) != 0',
                           \ )
    if len(aliasesToRemove) != a:0
        let badAliases = filter(
                          \ copy(a:000),
                          \ 'index(aliasesToRemove, v:val) == -1',
                         \ )
        echohl ErrorMsg | echo "No such aliases: " . join(badAliases, ' ') | echohl NONE
        return
    en
    for alias in aliasesToRemove
        exec 'cunabbr' alias
    endfor
    call filter(s:aliases, 'index(aliasesToRemove, v:key) == -1')
endf

fun! s:Aliases(...)
    if a:0 == 0
        let goodAliases = keys(s:aliases)
    el
        let goodAliases = filter(copy(a:000), 'has_key(s:aliases, v:val) != 0')
    en

    if len(goodAliases) > 0
        let maxLhsLen = max(map(
                         \ copy(goodAliases),
                         \ 'strlen(v:val[0])',
                         \ )
                       \)
        echo join(map(copy(goodAliases), 'printf("%-".maxLhsLen."s %s", v:val, s:aliases[v:val])'), "\n")
    en
endf

let &cpo = s:save_cpo  | unlet s:save_cpo

