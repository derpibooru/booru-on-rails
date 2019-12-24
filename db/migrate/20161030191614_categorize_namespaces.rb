class CategorizeNamespaces < ActiveRecord::Migration[4.2]
  def change
    Tag.where(namespace: ['artist', 'editor', 'photographer']).update_all(category: 'origin')
    Tag.where(namespace: 'spoiler').update_all(category: 'spoiler')
    Tag.where(namespace: 'oc').update_all(category: 'oc')
    Tag.where(name: 'artist needed').update_all(category: 'error')
    Tag.where(name: 'oc').update_all(category: 'oc')
    Tag.where(name: ['anonymous artist', 'edit']).update_all(category: 'origin')
  end
end
