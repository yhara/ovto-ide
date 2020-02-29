require 'opal-parser'
require 'ovto'
require 'ovto-window'

module Ovto
  class Ide < Ovto::Middleware("ovto_ide")
    use Ovto::Window

    def setup
      actions.open_repl()
    end

    class State < Ovto::Ide::State
      item :repl_content, default: "1\n2\n3\n4\n5\n"
      item :repl_input, default: ""
    end

    class Actions < Ovto::Ide::Actions
      def open_repl
        actions.ovto_window.new_window(id: :ovto_ide_repl, top: 200)
      end

      def repl_input(str:)
        return {repl_input: str}
      end

      def repl_clear_input
        return {repl_input: ""}
      end

      def repl_eval
        input = state.repl_input
        console.log("input", input)
        new_content = state.repl_content + "\n" +
          input + " ->\n" +
          eval(input).inspect + "\n"
        actions.repl_clear_input()
        return {repl_content: new_content}
      end
    end

    class MainComponent < Ovto::Ide::Component
      def render
        o ".OvtoIdeMainComponent" do
          o Ovto::Window::OvtoWindow, window_id: :ovto_ide_repl do
            o Repl
          end
        end
      end

      class Repl < Ovto::Ide::Component
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
              }}, state.repl_content
            end
            o "input", {
              style: {width: "100%"},
              type: :text,
              value: state.repl_input,
              oninput: ->(e){ actions.repl_input(str: e.target.value); e.preventDefault() },
              onkeydown: ->(e){ actions.repl_eval() if e.key == "Enter"  }
            }
          end
        end
      end
    end
  end
end
