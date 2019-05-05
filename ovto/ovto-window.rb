require 'ovto'

module Ovto
  module Window
    class WindowState < Ovto::State
      item :id
      item :hidden, default: false
      item :top, default: 0
      item :left, default: 0
      item :width, default: 100
      item :height, default: 100

      item :drag_offset, default: nil
      item :resize_base, default: nil

      def hide
        merge(hidden: true)
      end

      def show
        merge(hidden: false)
      end

      def move(top:, left:)
        merge(top: top, left: left)
      end
    end

    class State < Ovto::State
      item :windows, default: [
        Ovto::Window::WindowState.new(id: 0, top: 200)
      ]
      item :ongoing_operation, default: nil  # :drag or :resize
      item :operating_window_id, default: nil

      def update_window(window)
        self.merge(windows: windows.map{|w|
          (w.id == window.id) ? window : w
        })
      end
    end

    module Actions
      module ControlBase
        def ovto_window_mousemove(event:)
          window = state.ovto_window.windows.find{|w| w.id == state.ovto_window.operating_window_id}
          case state.ovto_window.ongoing_operation
          when :drag
            actions.ovto_window_drag(x: event.pageX, y: event.pageY, window: window)
          when :resize
            actions.ovto_window_resize(x: event.pageX, y: event.pageY, window: window)
          end
        end

        def ovto_window_mouseup(event:)
          window = state.ovto_window.windows.find{|w| w.id == state.ovto_window.operating_window_id}
          case state.ovto_window.ongoing_operation
          when :drag
            actions.ovto_window_drag_end(window: window)
          when :resize
            actions.ovto_window_resize_end(window: window)
          end
        end

        def ovto_window_operation_start(window:, op:)
          return {ovto_window: state.ovto_window.merge(
            ongoing_operation: op, operating_window_id: window.id
          )}
        end

        def ovto_window_operation_end
          return {ovto_window: state.ovto_window.merge(
            ongoing_operation: nil, operating_window_id: nil
          )}
        end
      end
      include ControlBase

      module Dragging
        def ovto_window_drag_start(window:, event:)
          actions.ovto_window_operation_start(window: window, op: :drag)
          return {ovto_window: state.ovto_window.update_window(
            window.merge(drag_offset: [event.offsetX, event.offsetY])
          )}
        end

        def ovto_window_drag(window:, x:, y:)
          u, v = *window.drag_offset
          return {ovto_window: state.ovto_window.update_window(
            window.merge(left: x-u, top: y-v)
          )}
        end

        def ovto_window_drag_end(window:)
          actions.ovto_window_operation_end()
          return {ovto_window: state.ovto_window.update_window(
            window.merge(drag_offset: nil)
          )}
        end
      end
      include Dragging

      module Resizing
        def ovto_window_resize_start(window:, event:)
          actions.ovto_window_operation_start(window: window, op: :resize)
          return {ovto_window: state.ovto_window.update_window(
            window.merge(resize_base: [
              window.width, window.height, event.pageX, event.pageY
            ])
          )}
        end

        def ovto_window_resize(window:, x:, y:)
          w0, h0, u, v = *window.resize_base
          return {ovto_window: state.ovto_window.update_window(
            window.merge(width: w0 + x-u, height: h0 + y-v)
          )}
        end

        def ovto_window_resize_end(window:)
          actions.ovto_window_operation_end()
          return {ovto_window: state.ovto_window.update_window(
            window.merge(resize_base: nil)
          )}
        end
      end
      include Resizing
    end

    class MainComponent < Ovto::Component
      def render
        o ".OvtoWindowMainComponent" do
          state.ovto_window.windows.each do |w|
            next if w.hidden
            o OvtoWindow, window: w, content: "hello"
          end
        end
      end
    end

    class OvtoWindow < Ovto::Component
      def render(window:, content:)
        o ".OvtoWindow", {
          style: {
            position: :fixed,
            left: "#{window.left}px",
            top: "#{window.top}px",
            width: "#{window.width}px",
            height: "#{window.height}px",
            border: "1px solid black",
            background: :white,
            color: :black,
            display: :flex,
            "flex-direction": :column,
          }
        } do
          o TopBar, window: window
          o "div", {style: {"flex-grow": 1}}, content
          o ResizeHandleBar, window: window
        end
      end

      class TopBar < Ovto::Component
        def render(window:)
          o ".TopBar", {
            style: {
              height: "20px",
              width: "100%",
              "border-bottom": "1px solid black",
            },
            onmousedown: ->(e){ actions.ovto_window_drag_start(window: window, event: e); e.preventDefault() },
          } do
            o "span", "x"
          end
        end
      end

      class ResizeHandleBar < Ovto::Component
        def render(window:)
          o ".ResizeHandleBar", {
            style: {
              height: "20px",
              width: "100%",
              display: :flex,
            },
          } do
            o "span", {style: {"flex-grow": 1}}
            o ResizeHandle, window: window
          end
        end

        class ResizeHandle < Ovto::Component
          def render(window:)
            o ".ResizeHandle", {
              onmousedown: ->(e){ actions.ovto_window_resize_start(window: window, event: e); e.preventDefault(); e.stopPropagation() },
            }, "/"
          end
        end
      end
    end
  end
end
