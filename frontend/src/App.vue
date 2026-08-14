<template>
    <el-config-provider :locale="i18nLocale" :button="config" size="default">
        <router-view v-if="isRouterAlive" />
    </el-config-provider>
</template>

<script setup lang="ts">
import { reactive, computed, ref, nextTick, provide } from 'vue';
import en from 'element-plus/es/locale/lang/en';
import { useTheme } from '@/global/use-theme';
useTheme();

const config = reactive({
    autoInsertSpace: false,
});

const i18nLocale = computed(() => en);

const isRouterAlive = ref(true);

const reload = () => {
    isRouterAlive.value = false;
    nextTick(() => {
        isRouterAlive.value = true;
    });
};
provide('reload', reload);
</script>

<style scoped lang="scss"></style>
