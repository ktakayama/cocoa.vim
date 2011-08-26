" File: objc_cocoa_mappings.vim
" Author: Michael Sanders (msanders42 [at] gmail [dot] com)
" Description: Sets up mappings for cocoa.vim.
" Last Updated: December 26, 2009

if exists('b:cocoa_proj') || &cp || version < 700
	finish
endif
let b:cocoa_proj = fnameescape(globpath(expand('<afile>:p:h'), '*.xcodeproj'))
" Search a few levels up to see if we can find the project file
if empty(b:cocoa_proj)
	let b:cocoa_proj  = fnameescape(globpath(expand('<afile>:p:h:h'), '*.xcodeproj'))

	if empty(b:cocoa_proj)
		let b:cocoa_proj = fnameescape(globpath(expand('<afile>:p:h:h:h'), '*.xcodeproj'))
		if empty(b:cocoa_proj)
			let b:cocoa_proj = fnameescape(globpath(expand('<afile>:p:h:h:h:h'), '*.xcodeproj'))
		endif
	endif
endif
let g:x = b:cocoa_proj

com! -buffer ListMethods call objc#method_list#Activate(1)
com! -buffer -nargs=? -complete=customlist,objc#method_builder#Completion BuildMethods call objc#method_builder#Build('<args>')
com! -buffer -nargs=? -complete=custom,objc#man#Completion CocoaDoc call objc#man#ShowDoc('<args>')
com! -buffer -nargs=? Alternate call <SID>AlternateFile()

let objc_man_key = exists('objc_man_key') ? objc_man_key : 'K'
exe 'nn <buffer> <silent> '.objc_man_key.' :<c-u>call objc#man#ShowDoc()<cr>'

nn <buffer> <silent> <leader>A :cal<SID>AlternateFile()<cr>

" Mimic some of Xcode's mappings.
nn <buffer> <silent> <d-r> :w<bar>cal<SID>BuildAnd('launch')<cr>
nn <buffer> <silent> <d-b> :w<bar>cal<SID>XcodeRun('build')<cr>
nn <buffer> <silent> <d-K> :w<bar>cal<SID>XcodeRun('clean')<cr>
" TODO: Add this
" nn <buffer> <silent> <d-y> :w<bar>cal<SID>BuildAnd('debug')<cr>
nn <buffer> <silent> <d-m-up> :cal<SID>AlternateFile()<cr>
nn <buffer> <silent> <d-0> :call system('open -a Xcode '.b:cocoa_proj)<cr>
nn <buffer> <silent> <d-2> :<c-u>ListMethods<cr>
nm <buffer> <silent> <d-cr> <d-r>
ino <buffer> <silent> <f5> <c-x><c-o>
nn <buffer> <d-/> I// <ESC>
nn <buffer> <d-[> <<
nn <buffer> <d-]> >>

if exists('*s:AlternateFile') | finish | endif

" Switch from header file to implementation file (and vice versa).
fun s:AlternateFile()
	let path = expand('%:p:r').'.'
	let extensions = expand('%:e') == 'h' ? ['m', 'c', 'cpp'] : ['h']
	if !s:ReadableExtensionIn(path, extensions)
		  echoh ErrorMsg | echo 'Alternate file not readable.' | echoh None
	endif
endf

" Returns true and switches to file if file with extension in any of
" |extensions| is readable, or returns false if not.
fun s:ReadableExtensionIn(path, extensions)
	for ext in a:extensions
		if filereadable(a:path.ext)
			exe 'e'.fnameescape(a:path.ext)
			return 1
		endif
	endfor
	return 0
endf

" Opens Xcode and runs Applescript command.
fun s:XcodeRun(command)
	" Build   Cmd-B
	" Run     Cmd-R
	" Test    Cmd-U
	" Profile Cmd-I
	" Analyze Cmd-shift-B
	" Clean   Cmd-shift-K

	let command_replace = { 'launch': 'Run', 'build': 'Build', 'clean': 'Clean' }
	let cmd = get(command_replace, a:command, a:command)

	let command_map = { 'Build': 11, 'Run': 15, 'Test': 32, 'Profile': 34 }
	let command_shift_map = { 'Analyze': 11, 'Clean': 40 }

	if(get(command_map, cmd, "") != "")
		let code = command_map[cmd]. " using {command down}"
	elseif(get(command_shift_map, cmd, "") != "")
		let code = command_shift_map[cmd]. " using {command down, shift down}"
	end

	call system("open -a Xcode.app ".b:cocoa_proj." && osascript -e '"
				\ ."tell application \"Xcode\" to activate \r"
				\ ."tell application \"System Events\" \r"
				\ ."     tell process \"Xcode\" \r"
				\ ."          key code " .code. " \r"
				\ ."    end tell \r"
				\ ."end tell'")
endf

fun s:BuildAnd(command)
	call s:XcodeRun(a:command)
endf
