# README
SWFを使って動かしてみる

起動中のEC2インスタンス一覧を取得して、AMIを順次作成する
その際にオンデマンドインスタンスの場合はSTOP、STARTを行う
スポットインスタンスの場合は再起動なしでAMIを作成する

# 使い方

    $ bundle install --path vendor/bundle
    $ bundle exec ruby ./snapshot_cron_activity.rb
    $ bundle exec ruby ./snapshot_cron_workflow.rb
    $ bundle exec ruby ./snapshot_cron_workflow_starter.rb

AWS CLIで利用されるクレデンシャルファイルとリージョンが書かれたファイルが必要
具体的には~/.aws 以下のファイルを利用している
