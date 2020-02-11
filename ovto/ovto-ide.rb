require 'opal-parser'
require 'ovto'
require 'ovto-window'

module Ovto
  module Ide
    class State < Ovto::State
      item :repl_content, default: "1\n2\n3\n4\n5\n"
      item :repl_input, default: ""
    end

    module Actions
      def ovto_ide_open_repl
        actions.ovto_window.ovto_window_new(id: :ovto_ide_repl, top: 200)
      end

      def ovto_ide_repl_input(str:)
        return {ovto_ide: state.ovto_ide.merge(repl_input: str)}
      end

      def ovto_ide_repl_clear_input
        return {ovto_ide: state.ovto_ide.merge(repl_input: "")}
      end

      def ovto_ide_repl_eval
        input = state.ovto_ide.repl_input
        console.log("input", input)
        new_content = state.ovto_ide.repl_content + "\n" +
          input + " ->\n" +
          eval(input).inspect + "\n"
        actions.ovto_ide_repl_clear_input()
        return {ovto_ide: state.ovto_ide.merge(repl_content: new_content)}
      end
    end

    class MainComponent < Ovto::Component
      def render
        o ".OvtoIdeMainComponent" do
          o Ovto::Window::OvtoWindow, window_id: :ovto_ide_repl do
            o Repl
          end
        end
      end

      class Repl < Ovto::Component
        def render
          o '.OvtoIdeRepl', {
            style: {
              display: :flex,
              height: "100%",
              "flex-direction": :column,
            },
          } do
            o "div", {
              style: {
                "flex-grow": 1,
                "flex-basis": 0,
                "overflow-y": :scroll,
              }
            } do
              o "pre", {style: {
              }}, state.ovto_ide.repl_content
            end
            o "input", {
              style: {width: "100%"},
              type: :text,
              value: state.ovto_ide.repl_input,
              oninput: ->(e){ actions.ovto_ide_repl_input(str: e.target.value); e.preventDefault() },
              onkeydown: ->(e){ actions.ovto_ide_repl_eval() if e.key == "Enter"  }
            }
          end
        end
      end
    end
  end
end
