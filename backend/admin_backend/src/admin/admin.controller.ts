import { Body, Controller, Get, Param, Patch, Post, Req } from '@nestjs/common';
import { User as PrismaUser } from '@prisma/client';

import { AdminService } from './admin.service';

type AdminRequest = {
  adminUser?: PrismaUser;
};

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard/summary')
  dashboardSummary() {
    return this.adminService.getDashboardSummary();
  }

  @Get('businesses')
  businesses() {
    return this.adminService.listBusinesses();
  }

  @Post('businesses')
  createBusiness(@Req() req: AdminRequest, @Body() payload: Record<string, unknown>) {
    return this.adminService.createBusiness(req.adminUser!, payload);
  }

  @Patch('businesses/:vendorId')
  updateBusiness(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateBusiness(req.adminUser!, vendorId, payload);
  }

  @Get('businesses/:vendorId/overview')
  businessOverview(@Param('vendorId') vendorId: string) {
    return this.adminService.getBusinessOverview(vendorId);
  }

  @Get('businesses/:vendorId/orders')
  businessOrders(@Param('vendorId') vendorId: string) {
    return this.adminService.listBusinessOrders(vendorId);
  }

  @Patch('businesses/:vendorId/orders/:orderId/status')
  updateBusinessOrderStatus(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('orderId') orderId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateBusinessOrderStatus(
      req.adminUser!,
      vendorId,
      orderId,
      payload,
    );
  }

  @Get('businesses/:vendorId/sections')
  businessSections(@Param('vendorId') vendorId: string) {
    return this.adminService.listBusinessSections(vendorId);
  }

  @Post('businesses/:vendorId/sections')
  createBusinessSection(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.createBusinessSection(req.adminUser!, vendorId, payload);
  }

  @Patch('businesses/:vendorId/sections/:sectionId')
  updateBusinessSection(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('sectionId') sectionId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateBusinessSection(
      req.adminUser!,
      vendorId,
      sectionId,
      payload,
    );
  }

  @Get('businesses/:vendorId/products')
  businessProducts(@Param('vendorId') vendorId: string) {
    return this.adminService.listBusinessProducts(vendorId);
  }

  @Post('businesses/:vendorId/products')
  createBusinessProduct(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.createBusinessProduct(req.adminUser!, vendorId, payload);
  }

  @Patch('businesses/:vendorId/products/:productId')
  updateBusinessProduct(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('productId') productId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateBusinessProduct(
      req.adminUser!,
      vendorId,
      productId,
      payload,
    );
  }

  @Get('businesses/:vendorId/campaigns')
  businessCampaigns(@Param('vendorId') vendorId: string) {
    return this.adminService.listBusinessCampaigns(vendorId);
  }

  @Post('businesses/:vendorId/campaigns')
  createBusinessCampaign(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.createBusinessCampaign(req.adminUser!, vendorId, payload);
  }

  @Patch('businesses/:vendorId/campaigns/:campaignId')
  updateBusinessCampaign(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('campaignId') campaignId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateBusinessCampaign(
      req.adminUser!,
      vendorId,
      campaignId,
      payload,
    );
  }

  @Post('businesses/:vendorId/campaigns/:campaignId/toggle')
  toggleBusinessCampaign(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('campaignId') campaignId: string,
  ) {
    return this.adminService.toggleBusinessCampaign(req.adminUser!, vendorId, campaignId);
  }

  @Get('businesses/:vendorId/profile')
  businessProfile(@Param('vendorId') vendorId: string) {
    return this.adminService.getBusinessProfile(vendorId);
  }

  @Patch('businesses/:vendorId/profile')
  updateBusinessProfile(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateBusinessProfile(req.adminUser!, vendorId, payload);
  }

  @Get('orders')
  orders() {
    return this.adminService.listOrders();
  }

  @Get('users')
  users() {
    return this.adminService.listUsers();
  }

  @Post('users')
  createUser(@Req() req: AdminRequest, @Body() payload: Record<string, unknown>) {
    return this.adminService.createUser(req.adminUser!, payload);
  }

  @Patch('users/:userId')
  updateUser(
    @Req() req: AdminRequest,
    @Param('userId') userId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateUser(req.adminUser!, userId, payload);
  }

  @Get('events')
  events() {
    return this.adminService.listEvents();
  }

  @Post('events')
  createEvent(@Req() req: AdminRequest, @Body() payload: Record<string, unknown>) {
    return this.adminService.createEvent(req.adminUser!, payload);
  }

  @Patch('events/:eventId')
  updateEvent(
    @Req() req: AdminRequest,
    @Param('eventId') eventId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateEvent(req.adminUser!, eventId, payload);
  }

  @Get('finance/summary')
  financeSummary() {
    return this.adminService.getFinanceSummary();
  }

  @Get('reports/overview')
  reportsOverview() {
    return this.adminService.getReportsOverview();
  }

  @Get('notifications')
  notifications() {
    return this.adminService.listNotifications();
  }

  @Post('notifications')
  createNotification(
    @Req() req: AdminRequest,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.createNotification(req.adminUser!, payload);
  }

  @Patch('notifications/:notificationId')
  updateNotification(
    @Req() req: AdminRequest,
    @Param('notificationId') notificationId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateNotification(req.adminUser!, notificationId, payload);
  }

  @Get('support/tickets')
  supportTickets() {
    return this.adminService.listSupportTickets();
  }

  @Patch('support/tickets/:ticketId')
  updateSupportTicket(
    @Req() req: AdminRequest,
    @Param('ticketId') ticketId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateSupportTicket(req.adminUser!, ticketId, payload);
  }

  @Get('settings')
  settings() {
    return this.adminService.getSettings();
  }

  @Patch('settings')
  updateSettings(
    @Req() req: AdminRequest,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateSettings(req.adminUser!, payload);
  }
}
