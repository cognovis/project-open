
############
# Category Tree "@tree.tree_name@"
############
category_tree::import \
       -name {@tree.tree_name@} \
       -description {@tree.description@} \
       -locale $default_locale \
       -categories {<multiple name="categories">
           @categories.pad;noquote@@categories.level@   {@categories.name@}</multiple>
       }
