# frozen_string_literal: true

Neovim.plugin do |plug|
  plug.function(:CompleteRegisters, nargs: 2, sync: true) do |nvim, findstart, base|
    begin
      base = base.to_s
      if findstart.to_i == 1
        # Phase 1 - returns the column number to start auto-completion
        _, c = nvim.current.window.cursor
        line = nvim.current.line
        if line.strip.empty?
          c
        else
          line.rindex(' ', c) + 1
        end
      else
        completes = []
        regs = %w[" - . : * + ~ / % #]
        regs += ('0'..'9').to_a
        regs += ('a'..'z').to_a
        regs.each do |r|
          p = nvim.evaluate("getreg('#{r}')")
          unless p.valid_encoding?
            p = p.force_encoding('UTF-8').encode('UTF-16', invalid: :replace).encode('UTF-8')
          end
          p = p.strip unless p.empty?
          next if p.empty? # skip empty register
          completes << {
            word: p,
            kind: p.count("\n") + 1,
            menu: "[#{r}] RG",
            abbr: p.length > 50 ? "#{p[0..50]}..." : p,
            info: p,
            user_data: 'complete_registers',
            dup: 1, # show duplicates as well
          }
        end
        # Phase 2 - returns the list of candidates
        completes.select do |h|
          base.empty? || h[:word] =~ /^#{base}/
        end
      end
    rescue => _e
      # TODO: log error
    end
  end

  plug.autocmd(:CompleteDone, pattern: "*") do |nvim|
    completed_item = nvim.get_vvar('completed_item')
    if completed_item['user_data'] == 'complete_registers'
      # fix multiline text
      nvim.command('%s/[\x0]/\r/ge')
    end
  end
end
