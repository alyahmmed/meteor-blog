getPost = ->
  Post.first Session.get('postId')

# add new lines after block elements (visual)
formateHtml = (html) ->
  block = /\<\/(address|article|aside|audio|blockquote|canvas|dd|div|dl|fieldset|figcaption|figure|footer|form|h1|h2|h3|h4|h5|h6|header|hgroup|hr|noscript|ol|output|p|pre|section|table|tfoot|ul|video)\>(?!\n)/gmi
  html.replace(block, (match) ->
    "#{match}\n"
  )

Template.blogAdminEdit.rendered = ->
  Session.set('editorTemplate', 'visualEditor')
  Session.set('currentPost', getPost())

Template.visualEditor.rendered = ->
  @editor = new MediumEditor '.editable',
    placeholder: 'Start typing...'
    buttons:
      ['bold', 'italic', 'underline', 'anchor', 'pre', 'header1', 'header2', 'orderedlist', 'unorderedlist', 'quote', 'image']

Template.duoEditor.rendered = ->
  @editor = new MediumEditor '.editable',
    placeholder: 'Start typing...'
    buttons:
      ['bold', 'italic', 'underline', 'anchor', 'pre', 'header1', 'header2', 'orderedlist', 'unorderedlist', 'quote', 'image']

  $('.html-editor').height($('.editable').height())
  $('.editable').on('input', ->
    $('.html-editor').val($('.editable').html().trim())
    $('.html-editor').height($('.editable').height())
  )

Template.blogAdminEdit.helpers
  post: ->
    getPost() or {}

  editor: ->
    template: Session.get('editorTemplate')
    post: Session.get('currentPost')

Template.blogAdminEdit.events

  'click .visual-toggle': ->
    post = getPost()
    post.body = $('.html-editor').val().trim()
    Session.set('currentPost', post)
    Session.set('editorTemplate', 'visualEditor')
    $('.visual-toggle').addClass('selected')

  'click .html-toggle': ->
    post = getPost()
    post.body = formateHtml($('.editable').html().trim())
    Session.set('currentPost', post)
    Session.set('editorTemplate', 'htmlEditor')
    $('.html-toggle').addClass('selected')

  'click .visual-html-toggle': ->
    if $('.editable').get(0)
      post = getPost()
      post.body = formateHtml($('.editable').html().trim())
    else
      post = getPost()
      post.body = $('.html-editor').val().trim()

    Session.set('currentPost', post)
    Session.set('editorTemplate', 'duoEditor')

  'keyup .html-editor': ->
    $('.editable').html($('.html-editor').val())
    $('.html-editor').height($('.editable').height())

  'blur [name=title]': (e, tpl) ->
    e.preventDefault()
    slug = tpl.$('[name=slug]')
    title = $(e.currentTarget).val()

    if not slug.val()
      slug.val Post.slugify(title)

  'submit form': (e, tpl) ->
    e.preventDefault()
    form = $(e.currentTarget)

    if $('.editable').get(0)
      body = $('.editable', form).html().trim()
    else
      body = $('.html-editor').val().trim()

    slug = $('[name=slug]', form).val()

    if not body
      return alert 'Blog body is required'

    attrs =
      title: $('[name=title]', form).val()
      tags: $('[name=tags]', form).val()
      slug: slug
      body: body
      updatedAt: new Date()

    if getPost()
      post = getPost().update attrs
      if post.errors
        return alert(_(post.errors[0]).values()[0])

      Router.go 'blogAdmin'
    else
      Meteor.call 'doesBlogExist', slug, (err, exists) ->
        if not exists
          attrs.userId = Meteor.userId()
          post = Post.create attrs

          if post.errors
            return alert(_(post.errors[0]).values()[0])

          Router.go 'blogAdmin'

        else
          return alert 'Blog with this slug already exists'
