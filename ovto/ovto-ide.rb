require 'ovto'
require 'ovto-window'

module Ovto
  module Ide
    class State < Ovto::State
    end

    module Actions
      def ovto_ide_open_repl
        actions.ovto_window_new(id: :ovto_ide_repl, top: 200)
      end
    end

    class MainComponent < Ovto::Component
      def render
      end
    end
  end
end
