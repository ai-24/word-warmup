<template>
  <div class="relative">
    <input
      v-model.trim="searchWord"
      id="search-box"
      class="w-96 h-8 rounded outline outline-offset-0 outline-1 p-2"
      :placeholder="$t('incrementalSearch.placeholder')" />
    <div v-if="searchWord" class="absolute right-10 bottom-1.5">
      <button
        type="button"
        class="text-slate-400 hover:text-slate-600"
        @click="reset">
        ×
      </button>
    </div>
    <div class="absolute right-2 bottom-1">
      <p>
        <font-awesome-icon icon="fa-solid fa-magnifying-glass" size="lg" />
      </p>
    </div>
  </div>
  <div v-if="showSearchedExpressions && loaded">
    <div
      v-if="searchedExpressions.length === 0"
      class="border-solid border border-slate-500 border-t-white px-2.5 py-1 rounded-b-lg">
      <p>{{ $t('incrementalSearch.noData') }}</p>
    </div>
    <div
      v-else
      class="border-solid border border-slate-500 border-t-white px-2.5 py-1 rounded-b-lg">
      <ExpressionsList
        class="searched-expressions"
        :searchedExpressionsResources="searchedExpressions"></ExpressionsList>
    </div>
  </div>
  <div v-else-if="showSearchedExpressions && !loaded">
    <p>
      <font-awesome-icon
        icon="fa-solid fa-spinner"
        spin
        style="color: #747c8b" />
    </p>
  </div>
</template>

<script>
import ExpressionsList from './expressions-list.vue'
import Debounce from '../debounce'

export default {
  name: 'IncrementalSearch',
  components: { ExpressionsList },
  data() {
    return {
      searchWord: '',
      showSearchedExpressions: false,
      searchedExpressions: [],
      loaded: false
    }
  },
  watch: {
    searchWord() {
      this.searchExpressions()
    }
  },
  methods: {
    url() {
      return '/api/expressions?search_word=' + this.searchWord
    },
    async fetchExpressionsResources() {
      const expressionsResources = await fetch(this.url(), {
        method: 'GET',
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        credentials: 'same-origin'
      })
      return expressionsResources.json()
    },
    setupSearchedExpressions() {
      this.fetchExpressionsResources().then((response) => {
        this.searchedExpressions = response
        this.loaded = true
      })
    },
    searchExpressions: Debounce(function () {
      this.showSearchedExpressions = false
      this.loaded = false
      if (this.searchWord) {
        this.setupSearchedExpressions()
        this.showSearchedExpressions = true
      }
    }),
    reset() {
      this.searchWord = ''
    }
  }
}
</script>

<style scoped></style>