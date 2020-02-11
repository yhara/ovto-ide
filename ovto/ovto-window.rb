require 'ovto'

module Ovto
  class Window < Ovto::Middleware("ovto_window")
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

    class State < Ovto::Window::State
      item :windows, default: []
      item :ongoing_operation, default: nil  # :drag or :resize
      item :operating_window_id, default: nil

      def update_window(window)
        {windows: windows.map{|w|
          (w.id == window.id) ? window : w
        }}
      end
    end

    class Actions < Ovto::Window::Actions
      def ovto_window_new(state:, **args)
        window = Ovto::Window::WindowState.new(**args)
        return {windows: state.windows + [window]}
      end

      module ControlBase
        def ovto_window_mousemove(event:)
          window = state.windows.find{|w| w.id == state.operating_window_id}
          case state.ongoing_operation
          when :drag
            actions.ovto_window_drag(x: event.pageX, y: event.pageY, window: window)
          when :resize
            actions.ovto_window_resize(x: event.pageX, y: event.pageY, window: window)
          end
        end

        def ovto_window_mouseup(event:)
          window = state.windows.find{|w| w.id == state.operating_window_id}
          case state.ongoing_operation
          when :drag
            actions.ovto_window_drag_end(window: window)
          when :resize
            actions.ovto_window_resize_end(window: window)
          end
        end

        def ovto_window_operation_start(window:, op:)
          return {ongoing_operation: op, operating_window_id: window.id}
        end

        def ovto_window_operation_end
          return {ongoing_operation: nil, operating_window_id: nil}
        end
      end
      include ControlBase

      module Dragging
        def ovto_window_drag_start(window:, event:)
          actions.ovto_window_operation_start(window: window, op: :drag)
          return state.update_window(
            window.merge(drag_offset: [event.offsetX, event.offsetY])
          )
        end

        def ovto_window_drag(window:, x:, y:)
          u, v = *window.drag_offset
          return state.update_window(
            window.merge(left: x-u, top: y-v)
          )
        end

        def ovto_window_drag_end(window:)
          actions.ovto_window_operation_end()
          return state.update_window(
            window.merge(drag_offset: nil)
          )
        end
      end
      include Dragging

      module Resizing
        def ovto_window_resize_start(window:, event:)
          actions.ovto_window_operation_start(window: window, op: :resize)
          return state.update_window(
            window.merge(resize_base: [
              window.width, window.height, event.pageX, event.pageY
            ])
          )
        end

        def ovto_window_resize(window:, x:, y:)
          w0, h0, u, v = *window.resize_base
          return state.update_window(
            window.merge(width: w0 + x-u, height: h0 + y-v)
          )
        end

        def ovto_window_resize_end(window:)
          actions.ovto_window_operation_end()
          return state.update_window(
            window.merge(resize_base: nil)
          )
        end
      end
      include Resizing
    end

    class OvtoWindow < Ovto::Window::Component
      def render(window_id:, &block)
        window = state.windows.find{|w| w.id == window_id}
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
          o "div", {style: {"flex-grow": 1, display: :flex}} do
            o "div", {style: {"flex-grow": 1}}, &block
            o ResizeHandleBar, window: window
          end
        end
      end

      class TopBar < Ovto::Window::Component
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

      class ResizeHandleBar < Ovto::Window::Component
        def render(window:)
          o ".ResizeHandleBar", {
            style: {
              display: :flex,
              "flex-direction": :column,
            },
          } do
            o "span", {style: {"flex-grow": 1}}
            o ResizeHandle, window: window
          end
        end

        class ResizeHandle < Ovto::Window::Component
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
