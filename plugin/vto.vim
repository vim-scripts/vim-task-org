""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                                                              "
" File_Name__: vto.vim                                                         "
" Abstract___: Plugin for easy work with TODO/FIXME/etc marks in your code     "
"              (and more, see README for details)                              "
" Author_____: Alexander Yunin <use.skills@gmail.com>                          "
" Version____: 0.3.1                                                           "
" Last_Change: 09.09.11 17:11:00                                               "
" Licence____: BSD, see LICENSE                                                "
"                                                                              "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Date format for inserting date with :Di command
"See help for details
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists("g:vtoDateFormat")
    let g:vtoDateFormat = "%d.%m.%y %T"
endif
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Author name, if g:vtoName set in .vimrc
"then flag is a 1 and script use this name, if
"name not a set - flag = 0, and script use a
"system username.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists("g:vtoAuthorName")
  let s:vtoNFlag = 0
  if has('unix')
    let g:vtoAuthorName = "USER"
  elseif has('mac')
    let g:vtoAuthorName = "USER"
  elseif has('win32') || has('win64')
    let g:vtoAuthorName = "USERNAME"
  else
    let g:vtoAuthorName = "USER"
  end
else
  let s:vtoNFlag = 1
endif
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Comment's default dictionary, and user dictionary
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:vtoCommDict = {'ruby':'#', 'python':'#', 'c':'//', 'cpp':'//', 'sh':'#', 'vim':'"'}
if exists("g:vtoCommDictNew")
    :call extend(s:vtoCommDict, g:vtoCommDictNew)
endif
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Default commentary char. If comment-char not
"defined in dictionary and user dictionary, will 
"used this dictionary
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists("g:vtoDefaultComm")
    let g:vtoDefaultComm = '#'
endif
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Keywords for tasks preview
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists("g:vtoTokenList")
    let g:vtoTokenList = [":BUG:", ":FIXME:", ":TODO:", ":TRICKY:", ":WARNING:", "TODO", "FIXME"]
endif
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Insert data/task into buffer
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:InsMagick(flag, ...)
ruby << RUBY
if VIM::Buffer.current.line.empty?
  currline = ['']
else
  currline = VIM::Buffer.current.line.split('')
end

currpos = VIM::Window.current.cursor[1]
date_format = Vim.evaluate("g:vtoDateFormat")

case Vim.evaluate('a:flag')
when 0 
  fstr = currline[0..currpos] + 
         Time.now.strftime(date_format).split('') + 
         currline[currpos.succ..-1]
  VIM::Buffer.current.delete(VIM::Buffer.current.line_number)
  VIM::Buffer.current.append(VIM::Buffer.current.line_number.pred, fstr.join) 
when 1 
  case Vim.evaluate('s:vtoNFlag')
  when 0
    _author = ENV[Vim.evaluate('g:vtoAuthorName')]
    author = _author.nil? ? "Author" : _author
  when 1
    author = Vim.evaluate 'g:vtoAuthorName'
  end
  arg = Vim.evaluate('a:1').split
  ftype = Vim.evaluate('&ft')
  cdict = Vim.evaluate('s:vtoCommDict')
  if cdict[ftype].nil?
    Vim.message("Comment string for your filetype not defined.")
    Vim.message("Add in your .vimrc < let g:vtoCommDictNew = {'#{Vim.evaluate('&ft')}':'comment string'} >") if !Vim.evaluate('&ft').empty?
    commstr = Vim.evaluate('g:vtoDefaultComm')
  else
    commstr = cdict[ftype]
  end
  mess = arg[1..-1].join(' ')
  task = arg[0].split('').unshift(commstr, ':').push(': ').join
  fstr = currline[0..currpos] + 
         task.split('') +
         Time.now.strftime(date_format).split('').push(', ') +
         author.split('') +
         currline[currpos.succ..-1]
            
  VIM::Buffer.current.delete(VIM::Buffer.current.line_number)
  VIM::Buffer.current.append(VIM::Buffer.current.line_number.pred, fstr.join) 
  VIM::Buffer.current.append(VIM::Buffer.current.line_number, commstr + ' ' + mess)
else
  Vim.message('May_the_Force_be_with_you_always')
  return 0
end

RUBY
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Preview tasks in new buffer
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ViewTasks()
ruby << RUBY

kill_view_tasks_buf = lambda {
  Vim::Buffer.count.times do |t|
    if Vim::Buffer[t].name =~ /(vto-view-tasks)$/
      Vim.command('bwipeout! vto-view-tasks')
      break false
    end
    true
  end
}

if kill_view_tasks_buf.call
  preview_buf = []
  ft          = Vim.evaluate('&ft')
  current_buf = Array.new(Vim::Buffer.current.count) { |i| Vim::Buffer.current[i+1] }
  tokens      = Vim.evaluate('g:vtoTokenList')

  current_buf.each_with_index do |v,i| 
    tokens.each do |token|
      if v.include? token
        preview_buf << "[#{i.succ}] #{v}"                       # Format strings to [21] # :TODO: 02.07.2011, iflo0 
        preview_buf << "[#{i.succ.succ}] #{current_buf[i+1]}"   #                   [22] # Birthday party, lol
        preview_buf << "- - - - -"                              #                   - - - - -
        break
      end
    end
  end

  Vim.command 'rightbelow new vto-view-tasks'
#  Vim.command 'bunload! vto-view-tasks'
#  Vim.command 'sb vto-view-tasks'
  Vim.command "set ft=#{ft}"
  preview_buf.length.times { |t| Vim::Buffer.current.append t, preview_buf[t] }
end
RUBY
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Jump to selected task
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:JumpTask()
ruby <<RUBY

if Vim::Buffer.current.name =~ /(vto-view-tasks)$/
  if Vim::Buffer.current.line[0] == '[' || 91
    n = Vim::Buffer.current.line.scan(/(\[)(\w*)(\])/)[0][1].to_i
    Vim.command 'winc k'
    $curwin.cursor = [n, 1]
  end
end
RUBY
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


"Date insert
:command! Di :call s:InsMagick(0)
"
"Task insert
:command! Ti :call s:InsMagick(1, input("Type a taskname & task (TODO test it): "))
"
"View tasks
:command! Vt :call s:ViewTasks()
"
"Jump to task
:command! Jt :call s:JumpTask()
"
