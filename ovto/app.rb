require 'opal'
require 'ovto'
Ovto.log_error do
require 'ovto-ide'

class TodoApp < Ovto::App
  FILTERS = [:All, :Active, :Completed]

  use Ovto::Window

  def setup
    %x{
      document.addEventListener("mousemove", function(e){
        #{actions.ovto_window.mousemove(event: Native(`e`))}
      });
      document.addEventListener("mouseup", function(e){
        #{actions.ovto_window.mouseup(event: Native(`e`))}
      });
    }
    actions.ovto_ide_open_repl()
  end

  class Todo < Ovto::State
    item :id
    item :value
    item :done

    def self.filter(todos, filter)
      todos.select{|t|
        case filter
        when :Active then !t.done
        when :Completed then t.done
        else true
        end
      }
    end
  end

  class State < Ovto::State
    item :todos, default: []
    item :filter, default: FILTERS.first
    item :input, default: ""

    item :ovto_ide, default: Ovto::Ide::State.new
  end

  class Actions < Ovto::Actions
    include Ovto::Ide::Actions

    def add_todo
      new_todo = Todo.new(
        id: state.todos.length + 1,
        value: state.input,
        done: false
      )
      return {
        todos: state.todos + [new_todo],
        input: ""
      }
    end

    def destroy_todo(id:)
      return {todos: state.todos.reject{|t| t.id == id}}
    end

    def destroy_completed_todos
      return {todos: state.todos.reject(&:done)}
    end

    def toggle_todo(id:)
      new_todos = state.todos.map{|t|
        if t.id == id
          t.merge(done: !t.done)
        else
          t
        end
      }
      return {todos: new_todos}
    end

    def toggle_all(done:)
      return {todos: state.todos.map{|t| t.merge(done: done)}}
    end

    def set_input(value:)
      return {input: value}
    end

    def set_filter(filter:)
      return {filter: filter}
    end
  end

  class Header < Ovto::Component
    def render(input:)
      o 'header.header' do
        o 'h1', 'todos'
        o 'input.new-todo', {
          placeholder: "What needs to be done?",
          autofocus: true,
          value: input,
          onkeydown: ->(e){ actions.add_todo if e.keyCode == 13 },
          oninput: ->(e){ actions.set_input(value: e.target.value) },
        }
      end
    end
  end

  class TodoItem < Ovto::Component
    def render(todo:)
      o 'li', {class: todo.done && 'completed'} do
        o 'div.view' do
          o 'input.toggle', {
            type: 'checkbox',
            checked: todo.done,
            onchange: ->(){ actions.toggle_todo(id: todo.id) }
          }
          o 'label', todo.value
          o 'button.destroy', onclick: ->{ actions.destroy_todo(id: todo.id) }
        end
        o 'input.edit', {
          value: todo.value, #TODO
          onblur: ->{ handle_submit },
          onchange: ->{ handle_change },
          onkeydown: ->{ handle_keydown },
        }
      end
    end
  end

  class Main < Ovto::Component
    def render(todos:, current_filter:)
      o 'section.main' do
        o 'input#toggle-all.toggle-all', {
          type: 'checkbox',
          onchange: ->(e){ actions.toggle_all(done: e.target.checked) },
          checked: todos.all?(&:done)
        }
        o 'label', {for: 'toggle-all'}, 'Mark all as complete'
        o 'ul.todo-list' do
          Todo.filter(todos, current_filter).each do |todo|
            o TodoItem, key: todo.id, todo: todo
          end
        end
      end
    end
  end

  class Footer < Ovto::Component
    def render(left_count:, current_filter:)
      o 'footer.footer' do
        o 'span.todo-count' do
          o 'strong', left_count
          o 'text', ' item(s) left'
        end

        o 'ul.filters' do
          FILTERS.each do |filter|
            o 'li' do
              o 'a', {
                href: '#/',
                class: ('selected' if current_filter == filter),
                onclick: ->(){ actions.set_filter(filter: filter) }
              }, filter
            end
          end
        end
        o 'button.clear-completed', {
          onclick: ->(){ actions.destroy_completed_todos },
        }, 'Clear completed'
      end
    end
  end

  class StateInspector < Ovto::Component
    def render
      o '.StateInspector', style: {
        position: :fixed,
        top: 0,
        left: 0,
        bottom: 0, 'overflow-y': :auto, # Make it scrollable
        height: "100px",
        background: "#333",
        color: "#fff",
        opacity: 0.7,
        "z-index": 100, 
      } do
        o 'div', state.inspect
      end
    end
  end

  class MainComponent < Ovto::Component
    def render
      o '.MainComponent' do
        o 'section.todoapp' do
          o Header,
            input: state.input
          o Main, 
            todos: state.todos,
            current_filter: state.filter
          o Footer,
            left_count: state.todos.count{|t| !t.done},
            current_filter: state.filter
        end

        o StateInspector
        o Ovto::Ide::MainComponent
      end
    end
  end
end

TodoApp.run(id: 'ovto')
#Ovto.debug_trace = true

end # log_error
