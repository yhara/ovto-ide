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

      item :dragging, default: false
      item :drag_offset, default: nil

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

      def update_window(window)
        self.merge(windows: windows.map{|w|
          (w.id == window.id) ? window : w
        })
      end
    end

    module Actions
      def ovto_window_drag_start(window:, event:)
        return {ovto_window: state.ovto_window.update_window(
          window.merge(dragging: true, drag_offset: [event.offsetX, event.offsetY])
        )}
      end

      def ovto_window_mousemove(window:, event:)
        if window.dragging
          actions.ovto_window_drag(window: window, x: event.pageX, y: event.pageY)
        end
      end

      def ovto_window_drag(window:, x:, y:)
        u, v = *window.drag_offset
        return {ovto_window: state.ovto_window.update_window(
          window.merge(left: x-u, top: y-v)
        )}
      end

      def ovto_window_drag_end(window:)
        return {ovto_window: state.ovto_window.update_window(
          window.merge(dragging: false, drag_offset: nil)
        )}
      end
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
          },
          onmousedown: ->(e){ actions.ovto_window_drag_start(window: window, event: e); e.preventDefault() },
          onmousemove: ->(e){ actions.ovto_window_mousemove(window: window, event: e); e.preventDefault() },
          onmouseup:   ->(e){ actions.ovto_window_drag_end(window: window) },
        } do
          o TopBar
          o "div", content
        end
      end

      class TopBar < Ovto::Component
        def render
          o ".TopBar", {
            style: {
              height: "20px",
              width: "100%",
              "border-bottom": "1px solid black",
            },
          } do
            o "span", "_ x"
          end
        end
      end
    end
  end
end
