<template>
  <div ref="sidebarMenuC"
    class="fixed h-screen p-4 overflow-x-hidden overflow-y-scroll transition-all bg-primary-50 dark:border-gray-600 dark:bg-secondary-900 text-secondary-800 dark:text-secondary-100 duration-30 xl:relative scroll-smooth"
    :class="{ 'w-76': sideMenuStore.isFullSideMenu,'w-76 xl:w-20': !sideMenuStore.isFullSideMenu, 'top-0 start-0': sideMenuStore.isSideMenuOpen,'top-0 -left-76 xl:left-0': !sideMenuStore.isSideMenuOpen,}"
    >
    <!--  -->
    <!-- sidebar title -->

    <div  class="flex flex-row justify-center mt-4 ms-1 xl:ms-0 " :class="!sideMenuStore.isFullSideMenu ? '' : 'ps-2 pe-2'">
        <Link :href="route('admin.index')" class="flex flex-row">
            <div v-if="$page.props.backendLogo" class="rounded-lg pe-1" :class="!sideMenuStore.isFullSideMenu ? 'w-8 h-8' : 'h-12 w-12'">
                <img  v-lazy=" { src: $page.props.uploadUrl + '/' + $page.props.backendLogo.img_path, loading: $page.props.sysImageUrl+'/loading_gif.gif', error: $page.props.sysImageUrl+'/default_photo.png' }"

                class="object-contain rounded-lg" :class="!sideMenuStore.isFullSideMenu ? 'w-8 h-8' : 'h-12 w-12'"
                />
            </div>
        </Link>

        <!-- Mobile Menu Toggle -->
        <!-- <button @click="handleSidebarNavOpen(!sidebarNavOpen)" class="xl:hidden ">
            Menu Icons
            <ps-icon name="crossCircle" w="20" h="20" viewBox="0 0 27 27"   />
        </button> -->
    </div>
    <div  class="flex flex-row justify-center mt-4" :class="!sideMenuStore.isFullSideMenu ? '' : ''">
      <ps-label
                class="text-base font-semibold"
                :class="!sideMenuStore.isFullSideMenu ? 'xl:hidden' : 'ms-1 mt-1'">
                {{ $t('site_name') }}
            </ps-label>
    </div>

    <!-- search -->
    <div class="mt-5 mb-5" :class="sideMenuStore.isFullSideMenu ? 'flex' : 'flex xl:hidden'">
        <ps-input-with-right-icon v-model:value="searchterm"
        theme="bg-white dark:bg-secondaryDark-black border-none rounded-lg placeholder-secondary-800 dark:placeholder-secondary-200" class="flex w-full rounded-full" :placeholder="$t('core__be_search')" >
            <template #icon >
                <ps-icon name="search" class='cursor-pointer' theme="text-secondary-800 dark:text-secondary-200" />
            </template>
        </ps-input-with-right-icon>
    </div>
    <div class="flex items-center w-full p-1 mt-6 mb-8 rounded-lg text-secondary-800 bg-primary-50 hover:bg-primary-200 dark:hover:bg-secondary-700 dark:text-secondary-300 dark:bg-secondary-900"
    :class="sideMenuStore.isFullSideMenu ? 'hidden' : 'hidden xl:flex'"
     @click="handleSidebarFull">
        <ps-icon name="search" class='cursor-pointer' w="20" h="20" />
    </div>

    <!-- sidebar navigation -->
    <div class="grid grid-cols-1 divide-y-4">
        <div class="">
            
            <div v-for="menugroup in $page.props.menuGroups" :key="menugroup.id">
                <ps-label :class="{ 'flex': sideMenuStore.isFullSideMenu, 'hidden' : !sideMenuStore.isFullSideMenu }" class="mt-4 mb-2" v-if="searchterm==null && menugroup.is_invisible_group_name != 1"> {{ $t(menugroup.group_lang_key) }} </ps-label>
                <ps-label :class="{ 'flex': sideMenuStore.isFullSideMenu, 'hidden' : !sideMenuStore.isFullSideMenu }" class="mt-4 mb-2" v-else-if="menugroup.is_invisible_group_name != 1">
                    <span v-if="$t(menugroup.group_lang_key).toLowerCase().trim().includes(searchterm.toLowerCase().trim())">
                        {{ $t(menugroup.group_lang_key) }}
                    </span>
                    <span v-else-if="menugroup.sub_menu_group.filter(
                        (sub)=>$t(sub.sub_menu_lang_key).toLowerCase().trim().includes(searchterm.toLowerCase().trim()))
                        .length>0">
                        {{ $t(menugroup.group_lang_key) }}
                    </span>
                    <span v-else-if="menugroup.sub_menu_group.filter(
                        (sub)=> sub.is_dropdown==1 && sub.module.filter((module)=>
                            $t(module.module_lang_key).toLowerCase().trim().includes(searchterm.toLowerCase().trim())
                        ).length>0).length>0">
                        {{ $t(menugroup.group_lang_key) }}
                    </span>
                    <span v-else></span>
                </ps-label>
                <div v-for="group in menugroup.sub_menu_group" :key="group.id" class="mt-2">
                    <sidebar-menu-item v-model:dropDown="dropDownOpen" :group="group" :searchterm="searchterm" ></sidebar-menu-item>
                    <!-- <sidebar-menu-item v-if="group.module.length > 0 && group.is_dropdown == 1" :group="group" :searchterm="searchterm" ></sidebar-menu-item> -->
                    <!-- <sidebar-menu-item v-if="group.is_dropdown == 0" :group="group" :searchterm="searchterm" ></sidebar-menu-item>   -->
                </div>


            </div>

            <!-- Guaranteed Dressy C2C Finance & Escrow Navigation -->
            <div class="mt-4 pt-3 border-t border-gray-200 dark:border-secondary-700">
                <ps-label :class="{ 'flex': sideMenuStore.isFullSideMenu, 'hidden' : !sideMenuStore.isFullSideMenu }" class="mb-2 font-bold text-xs uppercase tracking-wider text-primary-600 dark:text-primary-400">
                    {{ $t('dressy_finance_group') || 'Dressy Finance & Escrow' }}
                </ps-label>
                <div class="space-y-1">
                    <Link :href="route('admin.orders.index')" class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors text-secondary-700 dark:text-secondary-300 hover:bg-primary-100 dark:hover:bg-secondary-800"
                        :class="{ 'bg-primary-500 !text-white font-semibold shadow-sm': route().current('admin.orders.*') }">
                        <ps-icon name="list" w="18" h="18" />
                        <span :class="{ 'inline': sideMenuStore.isFullSideMenu, 'hidden xl:hidden': !sideMenuStore.isFullSideMenu }">
                            {{ $t('dressy_orders_module') || 'Orders Management' }}
                        </span>
                    </Link>
                    <Link :href="route('admin.escrow.index')" class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors text-secondary-700 dark:text-secondary-300 hover:bg-primary-100 dark:hover:bg-secondary-800"
                        :class="{ 'bg-primary-500 !text-white font-semibold shadow-sm': route().current('admin.escrow.*') }">
                        <ps-icon name="cash" w="18" h="18" />
                        <span :class="{ 'inline': sideMenuStore.isFullSideMenu, 'hidden xl:hidden': !sideMenuStore.isFullSideMenu }">
                            {{ $t('dressy_escrow_module') || 'COD Escrow / Mark Paid' }}
                        </span>
                    </Link>
                    <Link :href="route('admin.wallets.index')" class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors text-secondary-700 dark:text-secondary-300 hover:bg-primary-100 dark:hover:bg-secondary-800"
                        :class="{ 'bg-primary-500 !text-white font-semibold shadow-sm': route().current('admin.wallets.*') }">
                        <ps-icon name="chart-line" w="18" h="18" />
                        <span :class="{ 'inline': sideMenuStore.isFullSideMenu, 'hidden xl:hidden': !sideMenuStore.isFullSideMenu }">
                            {{ $t('dressy_wallets_module') || 'Seller Wallets' }}
                        </span>
                    </Link>
                    <Link :href="route('admin.withdrawals.index')" class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors text-secondary-700 dark:text-secondary-300 hover:bg-primary-100 dark:hover:bg-secondary-800"
                        :class="{ 'bg-primary-500 !text-white font-semibold shadow-sm': route().current('admin.withdrawals.*') }">
                        <ps-icon name="bell" w="18" h="18" />
                        <span :class="{ 'inline': sideMenuStore.isFullSideMenu, 'hidden xl:hidden': !sideMenuStore.isFullSideMenu }">
                            {{ $t('dressy_withdrawals_module') || 'Withdrawal Requests' }}
                        </span>
                    </Link>
                    <Link :href="route('admin.commission.index')" class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors text-secondary-700 dark:text-secondary-300 hover:bg-primary-100 dark:hover:bg-secondary-800"
                        :class="{ 'bg-primary-500 !text-white font-semibold shadow-sm': route().current('admin.commission.*') }">
                        <ps-icon name="checkCircle" w="18" h="18" />
                        <span :class="{ 'inline': sideMenuStore.isFullSideMenu, 'hidden xl:hidden': !sideMenuStore.isFullSideMenu }">
                            {{ $t('dressy_commission_module') || 'Commission & Settings' }}
                        </span>
                    </Link>
                    <Link :href="route('admin.delivery.settings')" class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors text-secondary-700 dark:text-secondary-300 hover:bg-primary-100 dark:hover:bg-secondary-800"
                        :class="{ 'bg-primary-500 !text-white font-semibold shadow-sm': route().current('admin.delivery.*') }">
                        <ps-icon name="refresh" w="18" h="18" />
                        <span :class="{ 'inline': sideMenuStore.isFullSideMenu, 'hidden xl:hidden': !sideMenuStore.isFullSideMenu }">
                            {{ $t('dressy_delivery_settings_module') || 'Delivery Settings (Yalidine)' }}
                        </span>
                    </Link>
                </div>
            </div>

            <!-- Chabit AI Assistant & Vision Moderation Navigation -->
            <div class="mt-4 pt-3 border-t border-gray-200 dark:border-secondary-700">
                <ps-label :class="{ 'flex': sideMenuStore.isFullSideMenu, 'hidden' : !sideMenuStore.isFullSideMenu }" class="mb-2 font-bold text-xs uppercase tracking-wider text-purple-600 dark:text-purple-400">
                    Chabit AI
                </ps-label>
                <div class="space-y-1">
                    <Link :href="route('admin.chabit.settings')" class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors text-secondary-700 dark:text-secondary-300 hover:bg-primary-100 dark:hover:bg-secondary-800"
                        :class="{ 'bg-primary-500 !text-white font-semibold shadow-sm': route().current('admin.chabit.settings*') }">
                        <ps-icon name="cog" w="18" h="18" />
                        <span :class="{ 'inline': sideMenuStore.isFullSideMenu, 'hidden xl:hidden': !sideMenuStore.isFullSideMenu }">
                            Chabit AI Settings
                        </span>
                    </Link>
                    <Link :href="route('admin.chabit.messages')" class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors text-secondary-700 dark:text-secondary-300 hover:bg-primary-100 dark:hover:bg-secondary-800"
                        :class="{ 'bg-primary-500 !text-white font-semibold shadow-sm': route().current('admin.chabit.messages*') }">
                        <ps-icon name="chat" w="18" h="18" />
                        <span :class="{ 'inline': sideMenuStore.isFullSideMenu, 'hidden xl:hidden': !sideMenuStore.isFullSideMenu }">
                            Chabit Messages
                        </span>
                    </Link>
                </div>
            </div>
        </div>
        <div class="flex items-center justify-center py-2 my-2 ">
                    <ps-label
                        class="text-xs font-regular"
                        textColor="text-gray-500"
                        :class="!sideMenuStore.isFullSideMenu ? 'xl:hidden' : 'ms-1 mt-1'">
                        {{ $t('core__be_version') }} {{ $page.props.backendSetting.backend_version_no }}
                    </ps-label>
        </div>
    </div>
  </div>
</template>

<script>

import { Link } from '@inertiajs/vue3';
import { onMounted, onUnmounted, ref } from 'vue';
import SidebarMenuItem from '@/Components/Layouts/Sidebar/SidebarMenuItem.vue';
import SideBarTab from '@/Components/Layouts/Sidebar/SideBarTab.vue'
import PsLabel from "@/Components/Core/Label/PsLabel.vue";
import PsIcon from "@/Components/Core/Icons/PsIcon.vue";
import PsInputWithRightIcon from '@/Components/Core/Input/PsInputWithRightIcon.vue';
import { useSideMenuStore } from '../../../store/Menu/SideMenuStore';

export default {
  components:{ Link, SidebarMenuItem,SideBarTab,PsLabel,PsIcon,PsInputWithRightIcon},
  setup(){
    const searchterm = ref('')
    const sideMenuStore = useSideMenuStore();
    const dropDownOpen = ref('0');

    function handleSidebarNavOpen(v){
        sideMenuStore.setSideMenuOpenFlag(v);
    }
    function handleSidebarFull(v){
        sideMenuStore.setFullSideMenuFlag(v);
    }

    const sidebarMenuC = ref(null);

    function handleScroll(){
        localStorage.sidebarScroll = sidebarMenuC.value.scrollTop;
    }

    onUnmounted(() => {
        // sidebarMenuC.value.removeEventListener('scroll', handleScroll);
    })

    onMounted(() => {
        sidebarMenuC.value.addEventListener("scroll", handleScroll);

        if(localStorage.sidebarScroll != null){
            setTimeout(() => {
                sidebarMenuC.value.scrollTo(0,parseInt(localStorage.sidebarScroll));
            }, 1000);
        }
    })

    return{
        searchterm,
        handleSidebarFull,
        dropDownOpen,
        handleSidebarNavOpen,
        sidebarMenuC,
        sideMenuStore

    }
  },
};
</script>


