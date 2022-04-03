# Mandated by FR-13: Export.Notebook

json.extract! export, :id, :notebook_id, :ready, :created_at, :updated_at
json.url export_url(export, format: :json)
