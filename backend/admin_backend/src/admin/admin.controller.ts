import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  Param,
  Patch,
  Post,
  Query,
  Req,
} from '@nestjs/common';
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
  businesses(@Query() query: Record<string, unknown>) {
    return this.adminService.listBusinesses(query);
  }

  @Post('businesses/bulk')
  bulkUpdateBusinesses(@Req() req: AdminRequest, @Body() payload: Record<string, unknown>) {
    return this.adminService.bulkUpdateBusinesses(req.adminUser!, payload);
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

  @Delete('businesses/:vendorId')
  deleteBusiness(@Req() req: AdminRequest, @Param('vendorId') vendorId: string) {
    return this.adminService.deleteBusiness(req.adminUser!, vendorId);
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

  @Post('orders/bulk-status')
  bulkUpdateOrderStatus(@Req() req: AdminRequest, @Body() payload: Record<string, unknown>) {
    return this.adminService.bulkUpdateOrderStatus(req.adminUser!, payload);
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

  @Post('businesses/:vendorId/pickup-points')
  createBusinessPickupPoint(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.createBusinessPickupPoint(req.adminUser!, vendorId, payload);
  }

  @Patch('businesses/:vendorId/pickup-points/:pickupPointId')
  updateBusinessPickupPoint(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('pickupPointId') pickupPointId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateBusinessPickupPoint(
      req.adminUser!,
      vendorId,
      pickupPointId,
      payload,
    );
  }

  @Post('businesses/:vendorId/operators')
  createBusinessOperator(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.createBusinessOperator(req.adminUser!, vendorId, payload);
  }

  @Patch('businesses/:vendorId/operators/:operatorId')
  updateBusinessOperator(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('operatorId') operatorId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateBusinessOperator(
      req.adminUser!,
      vendorId,
      operatorId,
      payload,
    );
  }

  @Post('businesses/:vendorId/bank-accounts')
  createBusinessBankAccount(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.createBusinessBankAccount(req.adminUser!, vendorId, payload);
  }

  @Patch('businesses/:vendorId/bank-accounts/:bankAccountId')
  updateBusinessBankAccount(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('bankAccountId') bankAccountId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateBusinessBankAccount(
      req.adminUser!,
      vendorId,
      bankAccountId,
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

  @Delete('businesses/:vendorId/products/:productId')
  deleteBusinessProduct(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('productId') productId: string,
  ) {
    return this.adminService.deleteBusinessProduct(req.adminUser!, vendorId, productId);
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

  @Delete('businesses/:vendorId/campaigns/:campaignId')
  deleteBusinessCampaign(
    @Req() req: AdminRequest,
    @Param('vendorId') vendorId: string,
    @Param('campaignId') campaignId: string,
  ) {
    return this.adminService.deleteBusinessCampaign(req.adminUser!, vendorId, campaignId);
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
  orders(@Query() query: Record<string, unknown>) {
    return this.adminService.listOrders(query);
  }

  @Get('users')
  users(@Query() query: Record<string, unknown>) {
    return this.adminService.listUsers(query);
  }

  @Post('users/bulk')
  bulkUpdateUsers(@Req() req: AdminRequest, @Body() payload: Record<string, unknown>) {
    return this.adminService.bulkUpdateUsers(req.adminUser!, payload);
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

  @Delete('users/:userId')
  deleteUser(@Req() req: AdminRequest, @Param('userId') userId: string) {
    return this.adminService.deleteUser(req.adminUser!, userId);
  }

  @Get('events')
  events(@Query() query: Record<string, unknown>) {
    return this.adminService.listEvents(query);
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

  @Delete('events/:eventId')
  deleteEvent(@Req() req: AdminRequest, @Param('eventId') eventId: string) {
    return this.adminService.deleteEvent(req.adminUser!, eventId);
  }

  @Get('finance/summary')
  financeSummary() {
    return this.adminService.getFinanceSummary();
  }

  @Post('finance/payouts')
  createPayout(@Req() req: AdminRequest, @Body() payload: Record<string, unknown>) {
    return this.adminService.createPayout(req.adminUser!, payload);
  }

  @Patch('finance/payouts/:payoutId')
  updatePayout(
    @Req() req: AdminRequest,
    @Param('payoutId') payoutId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updatePayout(req.adminUser!, payoutId, payload);
  }

  @Get('reports/overview')
  reportsOverview() {
    return this.adminService.getReportsOverview();
  }

  @Get('notifications')
  notifications(@Query() query: Record<string, unknown>) {
    return this.adminService.listNotifications(query);
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

  @Delete('notifications/:notificationId')
  deleteNotification(
    @Req() req: AdminRequest,
    @Param('notificationId') notificationId: string,
  ) {
    return this.adminService.deleteNotification(req.adminUser!, notificationId);
  }

  @Get('support/tickets')
  supportTickets(@Query() query: Record<string, unknown>) {
    return this.adminService.listSupportTickets(query);
  }

  @Get('support/tickets/:ticketId')
  supportTicket(@Param('ticketId') ticketId: string) {
    return this.adminService.getSupportTicket(ticketId);
  }

  @Patch('support/tickets/:ticketId')
  updateSupportTicket(
    @Req() req: AdminRequest,
    @Param('ticketId') ticketId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateSupportTicket(req.adminUser!, ticketId, payload);
  }

  @Patch('support/tickets/:ticketId/assignment')
  updateSupportTicketAssignment(
    @Req() req: AdminRequest,
    @Param('ticketId') ticketId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.updateSupportTicketAssignment(
      req.adminUser!,
      ticketId,
      payload,
    );
  }

  @Post('support/tickets/:ticketId/messages')
  createSupportTicketMessage(
    @Req() req: AdminRequest,
    @Param('ticketId') ticketId: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.adminService.createSupportTicketMessage(
      req.adminUser!,
      ticketId,
      payload,
    );
  }

  @Post('uploads/presign')
  createUploadIntent(@Body() payload: Record<string, unknown>) {
    return this.adminService.createUploadIntent(payload);
  }

  @Get('audit-logs')
  auditLogs(@Query() query: Record<string, unknown>) {
    return this.adminService.listAuditLogs(query);
  }

  @Get('export/businesses')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  @Header('Content-Disposition', 'attachment; filename="businesses.csv"')
  exportBusinesses(@Query() query: Record<string, unknown>) {
    return this.adminService.exportBusinesses(query);
  }

  @Get('export/orders')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  @Header('Content-Disposition', 'attachment; filename="orders.csv"')
  exportOrders(@Query() query: Record<string, unknown>) {
    return this.adminService.exportOrders(query);
  }

  @Get('export/users')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  @Header('Content-Disposition', 'attachment; filename="users.csv"')
  exportUsers(@Query() query: Record<string, unknown>) {
    return this.adminService.exportUsers(query);
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
