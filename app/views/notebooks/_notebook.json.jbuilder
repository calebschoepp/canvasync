json.extract! notebook, :id, :name, :created_at, :updated_at
json.url notebook_url(notebook, format: :json)
