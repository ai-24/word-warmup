# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Quiz' do
  describe 'questions' do
    let!(:user) { FactoryBot.create(:user) }
    let!(:first_expression_items) { FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note, user_id: user.id)) }
    let!(:second_expression_items) { FactoryBot.create_list(:expression_item2, 3, expression: FactoryBot.create(:empty_note, user_id: user.id)) }
    let!(:third_expression_items) { FactoryBot.create_list(:expression_item3, 3, expression: FactoryBot.create(:empty_note, user_id: user.id)) }

    before do
      FactoryBot.create(:bookmarking, user:, expression: first_expression_items[0].expression)
      FactoryBot.create(:memorising, user:, expression: second_expression_items[0].expression)
    end

    it 'check questions when user has not logged in' do
      visit '/quiz'
      2.times do |n|
        click_button 'クイズに解答する'
        n < 1 ? click_button('次へ') : click_button('クイズの結果を確認する')
      end
      expect(all('.move-to-bookmark-or-memorised-list li', visible: false).count).to eq 1
      find('summary', text: 'ブックマークする英単語・フレーズ').click
      expect(page).to have_field 'balcony and Veranda'
    end

    it 'check questions when user has logged in' do
      OmniAuth.config.test_mode = true
      OmniAuth.config.add_mock(:google_oauth2, { uid: user.uid, info: { name: user.name } })

      visit '/'
      within '.button-on-header' do
        click_button 'Sign up/Log in with Google'
      end
      has_text? 'ログインしました'

      click_link 'クイズに挑戦'
      3.times do |n|
        click_button 'クイズに解答する'
        n < 2 ? click_button('次へ') : click_button('クイズの結果を確認する')
      end
      expect(all('.move-to-bookmark-or-memorised-list li', visible: false).count).to eq 1
      find('summary', text: 'ブックマークする英単語・フレーズ').click
      expect(page).to have_field "#{third_expression_items[0].content}, #{third_expression_items[1].content} and #{third_expression_items[2].content}"
    end
  end

  describe 'a quiz for everyone' do
    before do
      visit '/'
      click_link '試してみる(機能に制限あり)'
    end

    it 'check if there is no incremental search' do
      click_link 'クイズを試してみる'
      expect(page).not_to have_selector '.incremental-search'
    end

    it 'check if one question and no answer is on the question screen' do
      click_link 'クイズを試してみる'
      if has_text?('A platform on the side of a building, accessible from inside the building.')
        expect(page).to have_content 'A platform on the side of a building, accessible from inside the building.'
        expect(page).not_to have_content 'A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy'
        expect(page).not_to have_content 'balcony'
      else
        expect(page).to have_content(
          'A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.'
        )
        expect(page).not_to have_content 'A platform on the side of a building, accessible from inside the building.'
        expect(page).not_to have_content 'Veranda'
      end
    end

    it 'check if the correct answer is judged as right one' do
      click_link 'クイズを試してみる'
      if has_text?('A platform on the side of a building, accessible from inside the building.')
        fill_in('解答を入力', with: 'balcony')
      else
        fill_in('解答を入力', with: 'Veranda')
      end
      click_button 'クイズに解答する'
      expect(page).to have_content '◯ 正解!'
      expect(page).not_to have_content '× 不正解'
    end

    it 'check if the incorrect answer is judged as wrong one' do
      click_link 'クイズを試してみる'
      fill_in('解答を入力', with: 'terrace')
      click_button 'クイズに解答する'
      expect(page).not_to have_content '◯ 正解!'
      expect(page).to have_content '× 不正解'
      expect(page).to have_content '正解は{answer}です' # answerの値が取れているかはVue側でテストする
    end

    it 'check the feedback message if answer is not given by a user' do
      click_link 'クイズを試してみる'
      click_button 'クイズに解答する'
      expect(page).not_to have_content '◯ 正解!'
      expect(page).not_to have_content '× 不正解'
      expect(page).to have_content '× 正解は{answer}です'
    end

    it 'check the button and message on the last screen' do
      click_link 'クイズを試してみる'
      fill_in('解答を入力', with: 'balcony')
      click_button 'クイズに解答する'
      click_button '次へ'
      fill_in('解答を入力', with: 'veranda')
      click_button 'クイズに解答する'
      expect(page).to have_content '問題が全て出題されました'
      expect(page).to have_button 'クイズの結果を確認する'
      expect(page).not_to have_button '次へ'
    end
  end

  describe 'quiz result' do
    describe 'check if screens change' do
      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
      end

      it 'change the screen from quiz to result' do
        fill_in('解答を入力', with: 'balcony')
        click_button 'クイズに解答する'
        click_button '次へ'
        fill_in('解答を入力', with: 'veranda')
        click_button 'クイズに解答する'
        click_button 'クイズの結果を確認する'

        expect(page).not_to have_content '問題'
        expect(page).to have_content 'クイズお疲れ様でした！'
      end

      it 'show new quiz' do
        fill_in('解答を入力', with: '')
        click_button 'クイズに解答する'
        click_button '次へ'
        fill_in('解答を入力', with: 'veranda')
        click_button 'クイズに解答する'
        click_button 'クイズの結果を確認する'

        click_button 'クイズに再挑戦'
        expect(page).not_to have_content '{totalQuestions}問中{numberOfCorrectAnswers}問正解です'
        expect(page).to have_content '問題'
      end
    end

    describe 'show user answers when one answer is correct and one answer is incorrect' do
      let(:answers) { [] } # クイズの問題がランダムに出題されるため、クイズで入力した値をexampleで取得できるようにbeforeでこの配列に値を代入

      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        fill_in('解答を入力', with: 'wrong answer')
        click_button 'クイズに解答する'
        click_button '次へ'
        if has_text?('A platform on the side of a building, accessible from inside the building.')
          fill_in('解答を入力', with: 'Balcony')
          answers.push 'Balcony'
        else
          fill_in('解答を入力', with: 'veranda')
          answers.push 'veranda'
        end
        click_button 'クイズに解答する'
        click_button 'クイズの結果を確認する'
      end

      it 'check user answers list' do
        find('summary', text: '自分の解答を表示').click

        if answers[0] == 'Balcony'
          expect(page).to have_content '× wrong answer ( Answer: Veranda )'
          expect(page).to have_content('◯ Balcony')
        elsif answers[0] == 'veranda'
          expect(page).to have_content '× wrong answer ( Answer: balcony )'
          expect(page).to have_content('◯ veranda')
        end
      end
    end

    describe 'show user answers when an answer was not given' do
      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        fill_in('解答を入力', with: '')
        click_button 'クイズに解答する'
        click_button '次へ'
        fill_in('解答を入力', with: '')
        click_button 'クイズに解答する'
        click_button 'クイズの結果を確認する'
      end

      it 'show 無解答 if the user answer is blank' do
        find('summary', text: '自分の解答を表示').click
        expect(page).to have_content '× 無解答 ( Answer: balcony )'
        expect(page).to have_content '× 無解答 ( Answer: Veranda )'
      end
    end

    describe 'show important notice' do
      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        fill_in('解答を入力', with: '')
        click_button 'クイズに解答する'
        click_button '次へ'
        fill_in('解答を入力', with: 'veranda')
        click_button 'クイズに解答する'
        click_button 'クイズの結果を確認する'
      end

      it 'show important notice with red text color' do
        expect(page).to have_selector(
          '.important-notice',
          text: '重要: 一度この画面を離れると戻れません。今回の結果をブックマークや覚えた語彙リストに保存する場合は、下記ボタンをクリックする前に必ず行なってください。'
        )
      end
    end

    describe 'show user answers when questions were six' do
      before do
        2.times { FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note)) }

        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        5.times do
          fill_in('解答を入力', with: 'test')
          click_button 'クイズに解答する'
          click_button '次へ'
        end
        fill_in('解答を入力', with: '')
        click_button 'クイズに解答する'
        click_button 'クイズの結果を確認する'
      end

      it 'check if the right number of user answers are on the page when 自分の解答を表示 is clicked' do
        find('summary', text: '自分の解答を表示').click
        expect(all('ul.user-answer-list li').count).to eq 6
      end
    end

    context 'when one expression is in the list that go to bookmark and one expression is in the list that go to memorised words list' do
      let!(:expression) { FactoryBot.create(:empty_note) }
      let!(:first_expression_item) { FactoryBot.create(:expression_item, expression:) }
      let!(:second_expression_item) { FactoryBot.create(:expression_item2, expression:) }
      let(:answers) { [] } # クイズの問題がランダムに出題されるため、クイズで入力した値をexampleで取得できるようにbeforeでこの配列に値を代入

      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        fill_in('解答を入力', with: '')
        click_button 'クイズに解答する'
        click_button '次へ'
        3.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
            answers.push('balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
            answers.push('veranda')
          elsif has_text?(first_expression_item.explanation)
            fill_in('解答を入力', with: first_expression_item.content)
          elsif has_text?(second_expression_item.explanation)
            fill_in('解答を入力', with: second_expression_item.content)
          end

          click_button 'クイズに解答する'
          n < 2 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if one expression is in the list that goes to memorised words list' do
        expect(all('ul.list-of-correct-answers li').count).to eq 0

        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        if answers.count == 2
          expect(page).to have_content 'balcony and Veranda'
          expect(page).not_to have_content "#{first_expression_item.content} and #{second_expression_item.content}"
        else
          expect(page).to have_content "#{first_expression_item.content} and #{second_expression_item.content}"
          expect(page).not_to have_content 'balcony and Veranda'
        end

        expect(all('ul.list-of-correct-answers li').count).to eq 1
      end

      it 'check if one expression is in the list that go to bookmark' do
        expect(all('ul.list-of-wrong-answers li').count).to eq 0

        find('summary', text: 'ブックマークする英単語・フレーズ').click
        if answers.count == 2
          expect(page).to have_content "#{first_expression_item.content} and #{second_expression_item.content}"
          expect(page).not_to have_content 'balcony and Veranda'
        else
          expect(page).to have_content 'balcony and Veranda'
          expect(page).not_to have_content "#{first_expression_item.content} and #{second_expression_item.content}"
        end

        expect(all('ul.list-of-wrong-answers li').count).to eq 1
      end
    end

    context 'when two expressions are in memorised words list and zero expression is in bookmark list' do
      let!(:expression) { FactoryBot.create(:empty_note) }
      let!(:first_expression_item) { FactoryBot.create(:expression_item, expression:) }
      let!(:second_expression_item) { FactoryBot.create(:expression_item2, expression:) }
      let!(:third_expression_item) { FactoryBot.create(:expression_item3, expression:) }

      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        5.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
          elsif has_text?(first_expression_item.explanation)
            fill_in('解答を入力', with: first_expression_item.content)
          elsif has_text?(second_expression_item.explanation)
            fill_in('解答を入力', with: second_expression_item.content)
          elsif has_text?(third_expression_item.explanation)
            fill_in('解答を入力', with: third_expression_item.content)
          end
          click_button 'クイズに解答する'
          n < 4 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if memorised words list has two expressions' do
        expect(all('ul.list-of-correct-answers li').count).to eq 0

        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click

        expect(first('ul.list-of-correct-answers li')).to have_content 'balcony and Veranda'
        expect(all('ul.list-of-correct-answers li')[1]).to have_content(
          "#{first_expression_item.content}, #{second_expression_item.content} and #{third_expression_item.content}"
        )

        expect(page).not_to have_selector 'div.section-of-wrong-answers'
        expect(page).not_to have_content 'ブックマークする英単語・フレーズ'
      end
    end

    context 'when two expressions are in bookmark list and zero expression is in memorised words list' do
      let!(:first_expression_items) { FactoryBot.create_list(:expression_item, 3, expression: FactoryBot.create(:empty_note)) }

      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        2.times do
          fill_in('解答を入力', with: 'wrong answer')
          click_button 'クイズに解答する'
          click_button '次へ'
          fill_in('解答を入力', with: '')
          click_button 'クイズに解答する'
          click_button('次へ')
        end
        fill_in('解答を入力', with: '')
        click_button 'クイズに解答する'
        click_button('クイズの結果を確認する')
      end

      it 'check if bookmark list has two expressions' do
        expect(all('ul.list-of-wrong-answers li').count).to eq 0

        find('summary', text: 'ブックマークする英単語・フレーズ').click
        expect(first('ul.list-of-wrong-answers li')).to have_content 'balcony and Veranda'
        expect(all('ul.list-of-wrong-answers li')[1]).to have_content(
          "#{first_expression_items[0].content}, #{first_expression_items[1].content} and #{first_expression_items[2].content}"
        )

        expect(page).not_to have_selector 'div.section-of-correct-answers'
        expect(page).not_to have_content '覚えた語彙リストに保存する英単語・フレーズ'
      end
    end

    describe 'checkbox for memorised words list' do
      let!(:expression) { FactoryBot.create(:empty_note) }
      let!(:first_expression_item) { FactoryBot.create(:expression_item, expression:) }
      let!(:second_expression_item) { FactoryBot.create(:expression_item2, expression:) }

      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        4.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
          elsif has_text?(first_expression_item.explanation)
            fill_in('解答を入力', with: first_expression_item.content)
          elsif has_text?(second_expression_item.explanation)
            fill_in('解答を入力', with: second_expression_item.content)
          end
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if all checkbox is checked' do
        expect(page).to have_checked_field 'move-to-memorised-list'
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        expect(page).to have_checked_field 'balcony and Veranda'
        expect(page).to have_checked_field "#{first_expression_item.content} and #{second_expression_item.content}"
      end

      it 'check if the parents checkbox is unchecked when one expression is unchecked' do
        expect(page).to have_checked_field 'move-to-memorised-list'
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        expect(page).to have_unchecked_field 'move-to-memorised-list'
        expect(page).to have_checked_field "#{first_expression_item.content} and #{second_expression_item.content}"
      end

      it 'check if parents checkbox is checked after one child checkbox is unchecked and then it is checked again' do
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        expect(page).to have_unchecked_field 'move-to-memorised-list'
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_checked_field 'balcony and Veranda'
        expect(page).to have_checked_field 'move-to-memorised-list'
      end

      it 'check if all the child checkbox is unchecked when parents checkbox is clicked to uncheck' do
        find('input#move-to-memorised-list').click
        expect(page).to have_unchecked_field 'move-to-memorised-list'
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        expect(page).to have_unchecked_field "#{first_expression_item.content} and #{second_expression_item.content}"
      end
    end

    describe 'checkbox for bookmark' do
      let!(:first_expression_items) { FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note)) }

      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        4.times do |n|
          fill_in('解答を入力', with: '')
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if all checkbox is checked' do
        expect(page).to have_checked_field 'move-to-bookmark'
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        expect(page).to have_checked_field 'balcony and Veranda'
        expect(page).to have_checked_field "#{first_expression_items[0].content} and #{first_expression_items[1].content}"
      end

      it 'check if the parents checkbox is unchecked when one expression is unchecked' do
        expect(page).to have_checked_field 'move-to-bookmark'
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        expect(page).to have_unchecked_field 'move-to-bookmark'
        expect(page).to have_checked_field "#{first_expression_items[0].content} and #{first_expression_items[1].content}"
      end

      it 'check if parents checkbox is checked after one child checkbox is unchecked and then it is checked again' do
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        expect(page).to have_unchecked_field 'move-to-bookmark'
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_checked_field 'balcony and Veranda'
        expect(page).to have_checked_field 'move-to-bookmark'
      end

      it 'check if all the child checkbox is unchecked when parents checkbox is clicked to uncheck' do
        find('input#move-to-bookmark').click
        expect(page).to have_unchecked_field 'move-to-bookmark'
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        expect(page).to have_unchecked_field "#{first_expression_items[0].content} and #{first_expression_items[1].content}"
      end
    end

    describe 'checkbox for bookmark and memorised words list' do
      let!(:first_expression_items) { FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note)) }

      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'
        4.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
          elsif has_text?(first_expression_items[0].explanation)
            fill_in('解答を入力', with: first_expression_items[0].content)
          else
            fill_in('解答を入力', with: '')
          end
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if checkbox for bookmark does not affect memorised words list' do
        expect(page).to have_checked_field 'move-to-bookmark'
        expect(page).to have_checked_field 'move-to-memorised-list'
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        find('label', text: "#{first_expression_items[0].content} and #{first_expression_items[1].content}").click
        expect(page).to have_unchecked_field 'move-to-bookmark'
        expect(page).to have_checked_field 'move-to-memorised-list'
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        expect(page).to have_checked_field 'balcony and Veranda'
      end

      it 'check if checkbox for memorised words list does not affect bookmark' do
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_unchecked_field 'move-to-memorised-list'
        expect(page).to have_checked_field 'move-to-bookmark'
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        expect(page).to have_checked_field "#{first_expression_items[0].content} and #{first_expression_items[1].content}"
      end
    end

    describe 'bookmark' do
      let!(:first_expression_items) { FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note)) }
      let(:user) { FactoryBot.build(:user) }

      before do
        OmniAuth.config.test_mode = true
        OmniAuth.config.add_mock(:google_oauth2, { uid: user.uid, info: { name: user.name } })

        visit '/'
        within '.welcome' do
          click_button 'Sign up/Log in with Google'
        end
        has_text? 'ログインしました'

        click_link 'クイズに挑戦'

        4.times do |n|
          fill_in('解答を入力', with: '')
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if all expressions in the list that goes to bookmark are bookmarked' do
        expect(page).to have_checked_field 'move-to-bookmark'
        expect(page).to have_content user.name
        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content 'ブックマークしました！'
        end.to change(Bookmarking, :count).by(2)
      end

      it 'check if selected expression is bookmarked' do
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        expect(page).to have_checked_field "#{first_expression_items[0].content} and #{first_expression_items[1].content}"
        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content 'ブックマークしました！'
        end.to change(Bookmarking, :count).by(1)
      end

      it 'check if one expression is bookmarked even if another one is failed to bookmark' do
        expression_item = ExpressionItem.where(content: first_expression_items[0].content).last
        expression_item.expression.destroy
        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content "ブックマークしました！\n(存在が確認できなかった英単語・フレーズを除く)"
        end.to change(Bookmarking, :count).by(1)
      end

      it 'check notification when expressions are failed to bookmark' do
        expression_item = ExpressionItem.where(content: 'balcony').last
        expression_item.expression.destroy
        expression_item = ExpressionItem.where(content: first_expression_items[0].content).last
        expression_item.expression.destroy
        expect do
          click_button '保存する'
          expect(page).to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content 'ブックマークできませんでした'
        end.to change(Bookmarking, :count).by(0)
      end

      it 'check if expression is bookmarked after failing to save another one' do
        ExpressionItem.where(content: first_expression_items[0].content).last.expression.destroy
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        click_button '保存する'
        expect(page).to have_content 'ブックマークできませんでした'

        find('label', text: 'balcony and Veranda').click
        expect(page).to have_checked_field 'balcony and Veranda'
        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content "ブックマークしました！\n(存在が確認できなかった英単語・フレーズを除く)"
        end.to change(Bookmarking, :count).by(1)
      end

      it 'check quiz questions after bookmarking' do
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click

        click_button '保存する'
        expect(page).to have_content 'ブックマークしました！'
        click_button 'クイズに再挑戦'

        2.times do |n|
          fill_in('解答を入力', with: '')
          click_button 'クイズに解答する'
          n < 1 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end

        find('summary', text: 'ブックマークする英単語・フレーズ').click
        expect(page).to have_content 'balcony and Veranda'
        expect(page).not_to have_content "#{first_expression_items[0].content} and #{first_expression_items[1].content}"
      end
    end

    describe 'save to memorised words list' do
      let!(:expression) { FactoryBot.create(:empty_note) }
      let!(:first_expression_item) { FactoryBot.create(:expression_item, expression:) }
      let!(:second_expression_item) { FactoryBot.create(:expression_item2, expression:) }
      let(:user) { FactoryBot.build(:user) }

      before do
        OmniAuth.config.test_mode = true
        OmniAuth.config.add_mock(:google_oauth2, { uid: user.uid, info: { name: user.name } })

        visit '/'
        within '.welcome' do
          click_button 'Sign up/Log in with Google'
        end
        has_text? 'ログインしました'

        click_link 'クイズに挑戦'

        4.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
          elsif has_text?(first_expression_item.explanation)
            fill_in('解答を入力', with: first_expression_item.content)
          elsif has_text?(second_expression_item.explanation)
            fill_in('解答を入力', with: second_expression_item.content)
          end
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if all expressions in the list that goes to memorised words list are saved' do
        expect(page).to have_checked_field 'move-to-memorised-list'
        expect(page).to have_content user.name
        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content '覚えた語彙リストに保存しました！'
        end.to change(Memorising, :count).by(2)
      end

      it 'check if selected expression is saved to memorised words list' do
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        expect(page).to have_checked_field "#{first_expression_item.content} and #{second_expression_item.content}"
        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content '覚えた語彙リストに保存しました！'
        end.to change(Memorising, :count).by(1)
      end

      it 'check if one expression is saved to memorised words list even if another one is failed to save' do
        expression_item = ExpressionItem.where(content: first_expression_item.content).last
        expression_id = expression_item.expression.id
        expression_item.expression.destroy
        expect(Expression.exists?(id: expression_id)).to be false
        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content "覚えた語彙リストに保存しました！\n(存在が確認できなかった英単語・フレーズを除く)"
        end.to change(Memorising, :count).by(1)
      end

      it 'check notification when expressions are failed to saved in memorised words list' do
        expression_item = ExpressionItem.where(content: 'balcony').last
        expression_item.expression.destroy
        expression_item2 = ExpressionItem.where(content: first_expression_item.content).last
        expression_item2.expression.destroy
        expect do
          click_button '保存する'
          expect(page).to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content '覚えた語彙リストに保存できませんでした'
        end.to change(Memorising, :count).by(0)
      end

      it 'check if expression is saved to memorised words list after failing to save another one' do
        ExpressionItem.where(content: first_expression_item.content).last.expression.destroy
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        expect(page).to have_unchecked_field 'balcony and Veranda'
        click_button '保存する'
        expect(page).to have_content '覚えた語彙リストに保存できませんでした'

        find('label', text: 'balcony and Veranda').click
        expect(page).to have_checked_field 'balcony and Veranda'
        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content "覚えた語彙リストに保存しました！\n(存在が確認できなかった英単語・フレーズを除く)"
        end.to change(Memorising, :count).by(1)
      end

      it 'check quiz questions after saving expressions to memorised words list' do
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click
        click_button '保存する'
        expect(page).to have_content '覚えた語彙リストに保存しました！'
        click_button 'クイズに再挑戦'

        2.times do |n|
          click_button 'クイズに解答する'
          n < 1 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end

        find('summary', text: 'ブックマークする英単語・フレーズ').click
        expect(page).to have_content 'balcony and Veranda'
        expect(page).not_to have_content "#{first_expression_item.content} and #{second_expression_item.content}"
      end
    end

    describe 'one expression is bookmarked and one expression is saved to memorised words list' do
      let!(:first_expression_items) { FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note)) }
      let(:user) { FactoryBot.build(:user) }

      before do
        OmniAuth.config.test_mode = true
        OmniAuth.config.add_mock(:google_oauth2, { uid: user.uid, info: { name: user.name } })

        visit '/'
        within '.welcome' do
          click_button 'Sign up/Log in with Google'
        end
        has_text? 'ログインしました'

        click_link 'クイズに挑戦'

        4.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
          elsif has_text?(first_expression_items[0].explanation)
            fill_in('解答を入力', with: first_expression_items[0].content)
          elsif has_text?(first_expression_items[1].explanation)
            fill_in('解答を入力', with: '')
          end
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if one expression is bookmarked and one expression is saved to memorised words list' do
        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content 'ブックマーク・覚えた語彙リストに保存しました！'
        end.to change(Memorising, :count).by(1).and change(Bookmarking, :count).by(1)
      end

      it 'check if one expression is bookmarked when failing to save memorised words list' do
        expression_item = ExpressionItem.where(content: 'balcony').last
        expression_item.expression.destroy

        expect do
          click_button '保存する'
          expect(page).to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content '英単語・フレーズをブックマークしましたが覚えた語彙リストには保存できませんでした'
          expect(page).not_to have_selector 'div.section-of-wrong-answers'
        end.to change(Memorising, :count).by(0).and change(Bookmarking, :count).by(1)
      end

      it 'check if one expression is saved to memorised words list when failing to bookmark' do
        expression_item = ExpressionItem.where(content: first_expression_items[0].content).last
        expression_item.expression.destroy

        expect do
          click_button '保存する'
          expect(page).to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content '覚えた語彙リストに保存しましたがブックマークは出来ませんでした'
          expect(page).not_to have_selector 'div.section-of-correct-answers'
        end.to change(Memorising, :count).by(1).and change(Bookmarking, :count).by(0)
      end

      it 'check notification when failing to bookmark and save to memorised words list' do
        expression_item = ExpressionItem.where(content: 'balcony').last
        expression_item.expression.destroy
        expression_item2 = ExpressionItem.where(content: first_expression_items[0].content).last
        expression_item2.expression.destroy

        expect do
          click_button '保存する'
          expect(page).to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content 'ブックマーク・覚えた語彙リストに保存できませんでした'
        end.to change(Memorising, :count).by(0).and change(Bookmarking, :count).by(0)
      end
    end

    describe 'two expressions are bookmarked and two expressions are saved to memorised words list' do
      let!(:expression) { FactoryBot.create(:empty_note) }
      let!(:first_expression_item) { FactoryBot.create(:expression_item, expression:) }
      let!(:second_expression_item) { FactoryBot.create(:expression_item2, expression:) }

      let!(:second_expression_items) { FactoryBot.create_list(:expression_item3, 2, expression: FactoryBot.create(:empty_note)) }
      let!(:third_expression_items) { FactoryBot.create_list(:expression_item4, 2, expression: FactoryBot.create(:empty_note)) }
      let(:user) { FactoryBot.build(:user) }

      before do
        OmniAuth.config.test_mode = true
        OmniAuth.config.add_mock(:google_oauth2, { uid: user.uid, info: { name: user.name } })

        visit '/'
        within '.welcome' do
          click_button 'Sign up/Log in with Google'
        end
        has_text? 'ログインしました'

        click_link 'クイズに挑戦'

        8.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
          elsif has_text?(first_expression_item.explanation)
            fill_in('解答を入力', with: first_expression_item.content)
          elsif has_text?(second_expression_item.explanation)
            fill_in('解答を入力', with: second_expression_item.content)
          elsif has_text?(second_expression_items[0].explanation)
            fill_in('解答を入力', with: '')
          elsif has_text?(second_expression_items[1].explanation)
            fill_in('解答を入力', with: '')
          elsif has_text?(third_expression_items[0].explanation)
            fill_in('解答を入力', with: '')
          elsif has_text?(third_expression_items[1].explanation)
            fill_in('解答を入力', with: '')
          end
          click_button 'クイズに解答する'
          n < 7 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if expressions are saved to memorised words list and bookmark when one expression is failed to bookmark' do
        expression_item = ExpressionItem.where(content: second_expression_items[0].content).last
        expression_item.expression.destroy

        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content "ブックマーク・覚えた語彙リストに保存しました！\n(存在が確認できなかった英単語・フレーズを除く)"
        end.to change(Memorising, :count).by(2).and change(Bookmarking, :count).by(1)
      end

      it 'check if expressions are saved to memorised words list and bookmarked when one expression is failed to save to memorised words list' do
        expression_item = ExpressionItem.where(content: first_expression_item.content).last
        expression_item.expression.destroy

        expect do
          click_button '保存する'
          expect(page).not_to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).to have_content "ブックマーク・覚えた語彙リストに保存しました！\n(存在が確認できなかった英単語・フレーズを除く)"
        end.to change(Memorising, :count).by(1).and change(Bookmarking, :count).by(2)
      end
    end

    describe 'After bookmarking and saving expressions to memorised words list' do
      let!(:expression) { FactoryBot.create(:empty_note) }
      let!(:first_expression_item) { FactoryBot.create(:expression_item, expression:) }
      let!(:second_expression_item) { FactoryBot.create(:expression_item2, expression:) }

      let!(:second_expression_items) { FactoryBot.create_list(:expression_item3, 2, expression: FactoryBot.create(:empty_note)) }
      let(:user) { FactoryBot.build(:user) }

      before do
        FactoryBot.create_list(:expression_item4, 2, expression: FactoryBot.create(:empty_note))

        OmniAuth.config.test_mode = true
        OmniAuth.config.add_mock(:google_oauth2, { uid: user.uid, info: { name: user.name } })

        visit '/'
        within '.welcome' do
          click_button 'Sign up/Log in with Google'
        end
        has_text? 'ログインしました'

        click_link 'クイズに挑戦'

        8.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
          elsif has_text?(first_expression_item.explanation)
            fill_in('解答を入力', with: first_expression_item.content)
          elsif has_text?(second_expression_item.explanation)
            fill_in('解答を入力', with: second_expression_item.content)
          end
          click_button 'クイズに解答する'
          n < 7 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
        find('summary', text: '覚えた語彙リストに保存する英単語・フレーズ').click
        find('label', text: 'balcony and Veranda').click

        find('summary', text: 'ブックマークする英単語・フレーズ').click
        find('label', text: "#{second_expression_items[0].content} and #{second_expression_items[1].content}").click
        click_button '保存する'
        has_text? 'ブックマーク・覚えた語彙リストに保存しました！'
        click_button 'クイズに再挑戦'

        4.times do |n|
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check what questions were in the last quiz' do
        find('summary', text: 'ブックマークする英単語・フレーズ').click
        expect(page).to have_content 'balcony and Veranda'
        expect(page).to have_content "#{second_expression_items[0].content} and #{second_expression_items[1].content}"
      end
    end

    describe 'show a message when user has not logged in and there are checkbox for bookmarks and saving to memorised words list' do
      before do
        FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note))

        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'

        4.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
          else
            fill_in('解答を入力', with: '')
          end
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check a message' do
        expect(page).to have_checked_field 'move-to-bookmark'
        expect(page).to have_checked_field 'move-to-memorised-list'

        expect do
          click_button '保存する'
          expect(page).to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).not_to have_content 'ブックマーク・覚えた語彙リストに保存できませんでした'
          expect(page).to have_content "ログインしていないため保存できません。\n保存するにはサインアップ / ログインしてください。"
        end.to change(Memorising, :count).by(0).and change(Bookmarking, :count).by(0)
      end
    end

    describe 'show a message when user has not logged in and  there is checkbox for bookmarks' do
      before do
        FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note))

        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'

        4.times do |n|
          fill_in('解答を入力', with: '')
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check a message' do
        expect(page).to have_checked_field 'move-to-bookmark'

        expect do
          click_button '保存する'
          expect(page).to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).not_to have_content 'ブックマーク・覚えた語彙リストに保存できませんでした'
          expect(page).to have_content "ログインしていないため保存できません。\n保存するにはサインアップ / ログインしてください。"
        end.to change(Bookmarking, :count).by(0)
      end
    end

    describe 'show a message when user has not logged in and  there is checkbox for saving to memorised words list' do
      let!(:expression) { FactoryBot.create(:empty_note) }
      let!(:first_expression_item) { FactoryBot.create(:expression_item, expression:) }
      let!(:second_expression_item) { FactoryBot.create(:expression_item2, expression:) }

      before do
        visit '/'
        click_link '試してみる(機能に制限あり)'
        click_link 'クイズを試してみる'

        4.times do |n|
          if has_text?('A platform on the side of a building, accessible from inside the building.')
            fill_in('解答を入力', with: 'balcony')
          elsif has_text?('A covered area in front of an entrance, normally on the ground floor and generally quite ornate or fancy, with room to sit.')
            fill_in('解答を入力', with: 'veranda')
          elsif has_text?(first_expression_item.explanation)
            fill_in('解答を入力', with: first_expression_item.content)
          elsif has_text?(second_expression_item.explanation)
            fill_in('解答を入力', with: second_expression_item.content)
          end
          click_button 'クイズに解答する'
          n < 3 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check a message' do
        expect(page).to have_checked_field 'move-to-memorised-list'

        expect do
          click_button '保存する'
          expect(page).to have_selector 'div.move-to-bookmark-or-memorised-list'
          expect(page).not_to have_content 'ブックマーク・覚えた語彙リストに保存できませんでした'
          expect(page).to have_content "ログインしていないため保存できません。\n保存するにはサインアップ / ログインしてください。"
        end.to change(Memorising, :count).by(0)
      end
    end

    describe 'button of クイズに再挑戦' do
      let(:user) { FactoryBot.build(:user) }

      before do
        OmniAuth.config.test_mode = true
        OmniAuth.config.add_mock(:google_oauth2, { uid: user.uid, info: { name: user.name } })

        visit '/'
        within '.welcome' do
          click_button 'Sign up/Log in with Google'
        end
        has_text? 'ログインしました'

        click_link 'クイズに挑戦'
        2.times do |n|
          click_button 'クイズに解答する'
          n < 1 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
      end

      it 'check if the quiz does not start when question is none' do
        click_button '保存する'
        expect(page).to have_content 'ブックマークしました！'
        expect(Expression.find_expressions_of_users_main_list(user.id).count).to eq 0

        click_button 'クイズに再挑戦'
        expect(page).to have_current_path '/home'
        expect(page).to have_content 'このリストのクイズに問題が存在しません'
      end

      it 'check if new quiz starts when questions exist' do
        click_button 'クイズに再挑戦'
        expect(page).to have_current_path '/quiz'
        expect(page).to have_css 'p.content-of-question'
      end
    end
  end
end
