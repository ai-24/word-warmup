# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Memorised expressions' do
  describe 'redirect' do
    let!(:user) { FactoryBot.create(:user) }
    let!(:first_expression_items) { FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note, user_id: user.id)) }

    before do
      FactoryBot.create(:memorising, user:, expression: first_expression_items[0].expression)
    end

    it 'check the page is redirected to 覚えたリスト after login' do
      OmniAuth.config.test_mode = true
      OmniAuth.config.add_mock(:google_oauth2, { uid: user.uid, info: { name: user.name } })

      visit home_path
      click_link '覚えた'
      expect(page).to have_current_path memorised_expressions_path
      expect(page).to have_content 'ログインしていないため閲覧できません'
      within '.button-on-header' do
        click_button 'Sign up / Log in with Google'
      end
      expect(page).to have_content 'ログインしました'
      expect(page).to have_current_path memorised_expressions_path
      expect(all('li.expression').count).to eq 1
      expect(page).not_to have_content 'ログインしていないため閲覧できません'
    end
  end

  context 'when user logged in' do
    context 'when there are no data of memorisings' do
      let(:user) { FactoryBot.build(:user) }

      before do
        FactoryBot.create_list(:expression_item, 3, expression: FactoryBot.create(:empty_note))
        FactoryBot.create_list(:expression_item2, 2, expression: FactoryBot.create(:empty_note))

        sign_in_with_welcome_page '.last-login-button', user
      end

      it 'show a message that there are no data' do
        expect(page).to have_content 'ログインしました'
        click_link '覚えた'
        expect(page).to have_current_path memorised_expressions_path
        expect(page).to have_content user.name
        expect(all('li.expression').count).to eq 0
        expect(page).to have_content 'このリストに登録している英単語・フレーズはありません'
      end

      it 'check tabs' do
        expect(page).to have_content 'ログインしました'
        visit '/memorised_expressions'
        within '.page_tabs' do
          expect(page).to have_link '未分類', href: home_path
          expect(page).to have_link '要復習', href: bookmarked_expressions_path
          expect(page).to have_link '覚えた', href: memorised_expressions_path
          click_link '要復習'
        end
        expect(page).to have_current_path bookmarked_expressions_path
        expect(page).to have_content 'このリストに登録している英単語・フレーズはありません'
        within '.page_tabs' do
          click_link '覚えた'
          find('a.words-and-phrases-link', text: '未分類').click
        end
        expect(all('li.expression').count).to eq 3
      end
    end

    context 'when there are data of memorisings' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:first_expression_items) { FactoryBot.create_list(:expression_item, 3, expression: FactoryBot.create(:empty_note, user_id: user.id)) }
      let!(:second_expression_items) { FactoryBot.create_list(:expression_item2, 2, expression: FactoryBot.create(:empty_note, user_id: user.id)) }

      before do
        expressions = []
        2.times do
          expressions.push(FactoryBot.create_list(:expression_item, 2, expression: FactoryBot.create(:empty_note, user_id: user.id)))
          expressions.push(FactoryBot.create_list(:expression_item2, 2, expression: FactoryBot.create(:empty_note, user_id: user.id)))
          expressions.push(FactoryBot.create_list(:expression_item3, 2, expression: FactoryBot.create(:empty_note, user_id: user.id)))
          expressions.push(FactoryBot.create_list(:expression_item4, 2, expression: FactoryBot.create(:empty_note, user_id: user.id)))
          expressions.push(FactoryBot.create_list(:expression_item5, 2, expression: FactoryBot.create(:empty_note, user_id: user.id)))
        end

        FactoryBot.create(:memorising, user:, expression: first_expression_items[0].expression)
        FactoryBot.create(:memorising, user:, expression: second_expression_items[0].expression)
        10.times do |n|
          FactoryBot.create(:memorising, user:, expression: expressions[n][0].expression)
        end

        sign_in_with_welcome_page '.first-login-button', user
      end

      it 'show a list of memorisings' do
        expect(page).to have_content 'ログインしました'
        click_link '覚えた'
        expect(page).to have_current_path memorised_expressions_path

        expect(all('li.expression').count).to eq 12
        expect(page).not_to have_content 'このリストに登録している英単語・フレーズはありません'
        expect(page).not_to have_content 'ログインしていないため閲覧できません'
      end

      it 'check titles and links' do
        expect(page).to have_content 'ログインしました'
        visit '/memorised_expressions'

        expect(first('li.expression')).to have_link(
          "#{first_expression_items[0].content}, #{first_expression_items[1].content} and #{first_expression_items[2].content}",
          href: expression_path(first_expression_items[0].expression)
        )
        expect(all('li.expression')[1]).to have_link "#{second_expression_items[0].content} and #{second_expression_items[1].content}",
                                                     href: expression_path(second_expression_items[0].expression)
      end

      it 'check tabs' do
        expect(page).to have_content 'ログインしました'
        click_link '覚えた'
        expect(page).to have_current_path memorised_expressions_path
        within '.page_tabs' do
          expect(page).to have_link '未分類', href: home_path
          expect(page).to have_link '要復習', href: bookmarked_expressions_path
          expect(page).to have_link '覚えた', href: memorised_expressions_path
          click_link '要復習'
        end
        expect(page).to have_current_path bookmarked_expressions_path
        expect(page).to have_content 'このリストに登録している英単語・フレーズはありません'
        within '.page_tabs' do
          click_link '覚えた'
          find('a.words-and-phrases-link', text: '未分類').click
        end
        expect(page).to have_current_path home_path
        expect(page).to have_content 'このリストに登録している英単語・フレーズはありません'
      end

      it 'check if there is incremental search' do
        expect(page).to have_content 'ログインしました'
        click_link '覚えた'
        expect(page).to have_current_path memorised_expressions_path
        expect(page).to have_selector '.incremental-search'
      end

      it 'check the link that goes to 覚えた list' do
        expect(page).to have_content 'ログインしました'
        click_link '覚えた'
        click_link "#{first_expression_items[0].content}, #{first_expression_items[1].content} and #{first_expression_items[2].content}"
        expect(page).to have_content first_expression_items[0].content
        expect(page).to have_content first_expression_items[1].content
        expect(page).to have_content first_expression_items[2].content
        expect(page).to have_content 'の違いについて'
        expect(page).to have_link '一覧に戻る'
        click_link '一覧に戻る'
        expect(page).to have_current_path memorised_expressions_path
      end
    end

    context 'when memorisings were made by two different times' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:expression) { FactoryBot.create(:empty_note, user_id: user.id) }
      let!(:first_expression_item) { FactoryBot.create(:expression_item, expression:) }
      let!(:second_expression_item) { FactoryBot.create(:expression_item2, expression:) }

      let!(:second_expression_items) { FactoryBot.create_list(:expression_item3, 2, expression: FactoryBot.create(:empty_note, user_id: user.id)) }
      let!(:third_expression_items) { FactoryBot.create_list(:expression_item4, 3, expression: FactoryBot.create(:empty_note, user_id: user.id)) }

      before do
        FactoryBot.create(:memorising, user:, expression: second_expression_items[0].expression)
        FactoryBot.create(:memorising, user:, expression: third_expression_items[0].expression)

        sign_in_with_welcome_page '.first-login-button', user
        has_text? 'ログインしました'

        click_link 'クイズに挑戦'

        2.times do |n|
          if has_text?(first_expression_item.explanation)
            fill_in('解答を入力', with: first_expression_item.content)
          elsif has_text?(second_expression_item.explanation)
            fill_in('解答を入力', with: second_expression_item.content)
          end
          click_button 'クイズに解答する'
          n < 1 ? click_button('次へ') : click_button('クイズの結果を確認する')
        end
        click_button '保存する'
        has_text? '覚えた英単語・フレーズのリストに保存しました！'

        visit '/memorised_expressions'
      end

      it 'check order' do
        expect(first('li.expression')).to have_link "#{second_expression_items[0].content} and #{second_expression_items[1].content}",
                                                    href: expression_path(second_expression_items[0].expression)
        expect(all('li.expression')[1]).to have_link(
          "#{third_expression_items[0].content}, #{third_expression_items[1].content} and #{third_expression_items[2].content}",
          href: expression_path(third_expression_items[0].expression)
        )
        expect(all('li.expression').last).to have_link "#{first_expression_item.content} and #{second_expression_item.content}",
                                                       href: expression_path(expression)
      end
    end
  end

  context 'when user is not logged in' do
    let(:user) { FactoryBot.build(:user) }

    before do
      sign_in_with_welcome_page '.first-login-button', user
      has_text? 'ログインしました'

      click_link 'クイズに挑戦'

      2.times do |n|
        if has_text?('A platform on the side of a building, accessible from inside the building.')
          fill_in('解答を入力', with: 'balcony')
        else
          fill_in('解答を入力', with: 'veranda')
        end
        click_button 'クイズに解答する'
        n < 1 ? click_button('次へ') : click_button('クイズの結果を確認する')
      end
      click_button '保存する'
      has_text? '覚えた英単語・フレーズのリストに保存しました！'

      visit '/home'
      find('label', text: user.name).click
      click_button 'Log out'
    end

    it 'show message that is not logged in' do
      expect(page).to have_content 'ログアウトしました'

      visit '/memorised_expressions'
      expect(page).to have_button 'Sign up / Log in with Google'
      expect(all('li.expression').count).to eq 0
      expect(page).to have_content 'ログインしていないため閲覧できません'
    end

    it 'check tabs' do
      expect(page).to have_content 'ログアウトしました'
      visit '/memorised_expressions'
      within '.page_tabs' do
        expect(page).to have_link '未分類', href: home_path
        expect(page).to have_link '要復習', href: bookmarked_expressions_path
        expect(page).to have_link '覚えた', href: memorised_expressions_path
        click_link '要復習'
      end
      expect(page).to have_current_path bookmarked_expressions_path
      expect(page).to have_content 'ログインしていないため閲覧できません'
      within '.page_tabs' do
        click_link '覚えた'
        find('a.words-and-phrases-link', text: '未分類').click
      end
      expect(page).to have_current_path home_path
      expect(all('li.expression').count).to eq 1
    end

    it 'check if there is no incremental search' do
      expect(page).to have_content 'ログアウトしました'

      visit '/memorised_expressions'
      expect(page).not_to have_selector '.incremental-search'
    end
  end
end
