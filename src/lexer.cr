require "./token.cr"

module CssParser
  class Lexer
    @token : Token
    @reader : Char::Reader

    def initialize(string : String)
      @token = Token.new
      @reader = Char::Reader.new(string)
    end

    def match_nmchar
      char = current_char
      if char == '_' || (char >= 'a' && char <= 'z') || \
          (char >= '0' && char <= '9') || char == '-'
        next_char
        return true
      end
      start_pos = current_pos
      if match_nonascii
        return true
      else
        set_current_pos(start_pos)
        if match_escape
          return true
        else
          return false
        end
      end
    end

    def match_nmstart
      char = current_char
      if char == '_' || (char >= 'a' && char <= 'z')
        next_char
        return true
      else
        start_pos = current_pos
        if match_nonascii
          return true
        else
          set_current_pos(start_pos)
          if match_escape
            return true
          else
            return false
          end
        end
      end
    end

    def match_nonascii
      char = current_char
      if !char.ord.in?(0..0x9f)
        next_char
        return true
      else
        return false
      end
    end

    def match_escape
      start_pos = current_pos
      if match_unicode
        return true
      else
        set_current_pos(start_pos)
        char = current_char
        if char == '\\'
          char = next_char
          if !char.in?("\n\r\f0123456789abcdef")
            next_char
            return true
          end
        else
          return false
        end
      end
    end

    def match_unicode
      char = current_char
      if char == '\\'
        char = next_char
        char_count = 1
        while true
          if char_count > 6
            break
          end
          if (char >= '0' && char <= '9') || (char >= 'a' && char <= 'f')
            char = next_char
            char_count += 1
          else
            if char_count == 1
              return false
            end
            break
          end
        end
        if char == '\r'
          char = next_char
          if char == '\n'
            next_char
          end
        elsif space?(char)
          next_char
        end
        true
      else
        false
      end
    end

    def space?(char : Char)
      if char.in?(" \n\r\t\f")
        return true
      else
        return false
      end
    end

    def match_string1
      char = current_char
      if char == '"'
        char = next_char
        while true
          if char == '"' || char == '\0'
            break
          end
          if char == '\\'
            char = next_char
            if char == '\\'
              # TODO: Check if this is correct
              if char.in?("\n") || char.in?("\r")
                char = next_char
              end
            end
          elsif !char.in?("\n\r\f\"") || match_escape
              char = next_char
          else
            return false
          end
        end
        return true
      else
        return false
      end
    end

    def scan_ident
      char = current_char
      if char == '-'
        next_char
      end

      if match_nmstart
        while current_char != '\0'
          match_nmchar
        end
        @token.type = :IDENT
      end
    end

    def scan_at_keyword
      char = current_char
      if char == '@'
        next_char
      end
      scan_ident
      @token.type = :ATKEYWORD
    end

    def next_token
      start_pos = current_pos
      char = current_char

      case char
      when '-'
        scan_ident
        @token.value = string_range(start_pos)
      when '@'
        scan_at_keyword
        @token.value = string_range(start_pos)
      end
      @token
    end

    def current_char
      @reader.current_char
    end

    def next_char
      @reader.next_char
    end

    def current_pos
      @reader.pos
    end

    def set_current_pos(pos)
      @reader.pos = pos
    end

    def string_range(start_pos, end_pos)
      @reader.string.byte_slice(start_pos, end_pos - start_pos)
    end

    def string_range(start_pos)
      string_range(start_pos, current_pos)
    end
  end
end
