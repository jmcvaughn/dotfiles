function! StatusLine(current, width)
  let l:s = ''

  " Left-justified
  if a:current
    let l:s .= crystalline#mode()
    let l:s .= crystalline#right_mode_sep('')
  else
    " Set entire statusbar to inactive highlight colour
    let l:s .= '%#CrystallineInactive#'
  endif
  let l:s .= ' %f %h%w%m%r'
  " Add space only when any of the non-filename fields are displayed. Some
  " (e.g. help) imply others (e.g. read-only). Ensures there is only ever one
  " space after the filename.
  if &modified || &readonly
    let l:s .= ' '
  endif
  if a:current
    let l:s .= crystalline#right_sep('', 'Fill')
    let l:s .= ' %{fugitive#head()}'
  endif

  let l:s .= '%='  " Right-justify

  " Right-justified
  if a:current
    if &paste || &spell
      let l:s .= crystalline#left_sep('', 'Fill')
      let l:s .= ' '
      let l:s .= '%{&paste ? "PASTE " : ""}'
      let l:s .= '%{&spell ? "SPELL " : ""}'
      let l:s .= crystalline#left_mode_sep('')
    else
      let l:s .= crystalline#left_mode_sep('Inactive')
    endif
  endif
  if a:width > 80
    let l:s .= ' %{&filetype}'
    let l:s .= ' [%{&fileencoding !=# "" ? &fileencoding:&encoding}]'
    let l:s .= '[%{&fileformat}]'
    let l:s .= ' %l/%L %c%V %P'
  endif
  let l:s .= ' '

  return l:s
endfunction

let g:crystalline_statusline_fn = 'StatusLine'
let g:crystalline_theme = 'gruvbox'
let g:crystalline_enable_sep = 1
