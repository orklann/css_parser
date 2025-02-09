module CssParser
  class Token
    enum Kind
      IDENT
      ATKEYWORD
      STRING
      EOF
    end

    property type : Kind
    property value : String | Nil

    def initialize
      @type = Kind::EOF
      @value = nil
    end
  end
end
