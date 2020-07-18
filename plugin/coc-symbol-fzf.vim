let s:symbol_kind = {
	\ '1': 'File',
	\ '2': 'Module',
	\ '3': 'Namespace',
	\ '4': 'Package',
	\ '5': 'Class',
	\ '6': 'Method',
	\ '7': 'Property',
	\ '8': 'Field',
	\ '9': 'Constructor',
	\ '10': 'Enum',
	\ '11': 'Interface',
	\ '12': 'Function',
	\ '13': 'Variable',
	\ '14': 'Constant',
	\ '15': 'String',
	\ '16': 'Number',
	\ '17': 'Boolean',
	\ '18': 'Array',
	\ '19': 'Object',
	\ '20': 'Key',
	\ '21': 'Null',
	\ '22': 'EnumMember',
	\ '23': 'Struct',
	\ '24': 'Event',
	\ '25': 'Operator',
	\ '26': 'TypeParameter',
	\ }

function! s:Kind2Symbol(kind) abort
  return has_key(s:symbol_kind, a:kind) ? s:symbol_kind[a:kind] : 'Unknown'
endfunction


let s:fetching = v:true

function! s:ExtractSymbol(symbols) abort
	let s:data = []

	if empty(a:symbols)
		return
	endif

	for item in a:symbols
		let s:text = item.name
		if !s:strict_match || s:text =~# s:symbol_match
			let s:kind = item.kind
			let s:filename = substitute(item.location.uri, '^file://', '', 'g')
			let s:lnum = item.location.range.start.line + 1
	
			let s:line = s:text . " [" . s:Kind2Symbol(s:kind) . "] " . "|" . s:filename . ":" . s:lnum
			call add(s:data, s:line)
		endif
	endfor

	if empty(s:data)
		echo "empty symbols"
	endif

	return s:data
endfunction

function! s:handle_lsp_symbol_response(error, response) abort
	if empty(a:error)
		" Refer to coc.nvim 79cb11e
		if a:response isnot v:null
			call s:ExtractSymbol(a:response)
		endif
	else
		call vista#error#Notify("Error when calling CocRequestAsync('workspace/symbol'): ".string(a:error))
	endif
	let s:fetching = v:false
endfunction

function! s:symbol_sink(line) abort
	let l:line = split(a:line, '|')[1]
	let l:filename = split(l:line, ':')[0]
	let l:lnum = split(a:line, ':')[1]

	execute "edit +" . l:lnum . " " . l:filename
endfunction

function! s:coc_symbol_fzf(bang, symbol) abort
	if a:bang
		let s:strict_match = v:true
	else
		let s:strict_match = v:false
	endif
	let s:symbol_match = a:symbol
	let s:fetching = v:true
	call CocRequestAsync('ccls', 'workspace/symbol', { 'query' : a:symbol }, function('s:handle_lsp_symbol_response'))
	while s:fetching
		sleep 100m
	endwhile
	call fzf#run(fzf#wrap({'source' : s:data, 'sink' : function('s:symbol_sink')}))
endfunction

command! -nargs=1 -bang Symbol call s:coc_symbol_fzf(<bang>0, <f-args>)


