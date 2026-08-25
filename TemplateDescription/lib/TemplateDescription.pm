package TemplateDescription;

use strict;
use warnings;

use MT;

sub plugin {
  return MT->component('TemplateDescription');
}

sub insert_before {
  my ( $tmpl, $name, $tokens ) = @_;

  my $before = $name
    ? $tmpl->getElementsByName($name)->[0]
    : undef;

  return unless $before;

  if ( !ref $tokens ) {
    $tokens = plugin()->load_tmpl($tokens)->tokens;
  }

  foreach my $token (@$tokens) {
    $tmpl->insertBefore( $token, $before );
  }
}

sub edit_template {
  my ( $cb, $app, $param, $tmpl ) = @_;

  # 既存テンプレートの場合は保存済みの説明文を取得
  if ( my $id = $app->param('id') ) {
    my $template = MT->model('template')->load($id);

    if ($template) {
      $param->{td_description}
        = $template->td_description || '';
    }
  }
  else {
    # 新規テンプレート
    $param->{td_description} = '';
  }

  # テンプレート本文の直前に説明欄を追加
  insert_before(
    $tmpl,
    'type_custom',
    'template_description.tmpl'
  );

  return 1;
}

sub template_source_template_table {
  my ( $cb, $app, $tmpl ) = @_;

  $$tmpl =~ s{
    (
      <td\b
      [^>]*
      \bclass="
      [^"]*
      \btemplate-name\b
      [^"]*
      "
      [^>]*
      >
      .*?
      </a>
    )
  }{
    $1
    <mt:if name="td_description">
      <div class="template-description small text-muted mt-1">
        <mt:var name="td_description" escape="html">
      </div>
    </mt:if>
  }sx;

  return 1;
}

sub pre_save_template {
  my ( $cb, $app, $obj, $original ) = @_;

  # 通常のテンプレート編集画面からの保存だけを対象にする
  my $mode = $app->mode;
  my $type = $app->param('_type') || '';

  return 1
    unless $mode eq 'save'
    && $type eq 'template';

  my $description = $app->param('td_description');

  $obj->td_description(
    defined $description ? $description : ''
  );

  return 1;
}

1;
